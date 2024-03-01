$ErrorActionPreference = "Stop"

$Shell = New-Object -ComObject shell.application

# Get the current directory name
$currentDir = (Get-Item -Path ".\").FullName
Write-Host "Current Directory Name: $currentDir"

# Iterate through each file
Get-ChildItem -Recurse -file *.jpg, *jpeg, *.mp4, *.mov, *.heic -ErrorAction Stop | ForEach-Object {
  $inFile = $_.Name
  $inPath = $_.DirectoryName
  $inFileDir = Split-Path -Leaf $inPath
  $inFileName = Join-Path -Path $inFileDir -ChildPath $inFile
  Write-Host "$inFileName..." -NoNewline

  $Folder = $Shell.NameSpace($_.DirectoryName)
  $File = $Folder.ParseName($_.Name)

  # Find the available property
  $Property = $Folder.GetDetailsOf($File, 12)
  if (-not $Property) {
    $Property = $Folder.GetDetailsOf($File, 3)
    if (-not $Property) {
      $Property = $Folder.GetDetailsOf($File, 4)
    }
  }

  # Get date in the required format as a string
  $RawDate = ($Property -Replace "[^\w /:]")
  $DateTime = [DateTime]::Parse($RawDate)
  $DateTaken2 = $DateTime.ToString("yyyy-MM-dd")
  $DateTakenYear = $DateTime.ToString("yyyy")

  # Loop over every directory in the path and find if any of the directories are named "Photographs"
  $photographsDirectory = $null
  $test_path = Split-Path -Parent $inPath

  while ($photographsDirectory -eq $null) {
    $test_leaf = Split-Path -Leaf $test_path
    if ($test_leaf -eq "Photographs") {
      $photographsDirectory = $test_path
      break
    }
    else {
      $test_path = Split-Path -Parent $test_path
    }
  }

  if ( $photographsDirectory -eq $null) {
    Write-Error "No 'Photographs' directory found"
  }

  # Define output directory based on date taken
  $parentDirectory = Join-Path -Path $photographsDirectory -ChildPath $DateTakenYear
  $outPath = Join-Path -Path $parentDirectory -ChildPath $DateTaken2

  # Check if inPath and outPath are the same
  if ( $inPath -eq $outPath) {
    write-host " OK" -ForegroundColor Green
  }
  else {
    write-host " MOVE" -ForegroundColor Red
    $outFileDir = Split-Path -Leaf $outPath
    $outFileName = Join-Path -Path $outFileDir -ChildPath $inFile

    # Check if outPath exists, and if not, create the directory
    if (-not (Test-Path -Path $outPath)) {
      write-host
      write-host "$outFileDir does not exist" # This is the directory where the file will be moved to
      New-Item -ItemType Directory -Path $outPath -Verbose
      write-host "$outFileName... " -NoNewline
    }
    else {
      Write-Host "exists" -ForegroundColor green
    }
    $outFilePath = Join-Path -Path $outPath -ChildPath $inFile

    # Check if outFileName exists
    if (Test-Path -Path $outFilePath -PathType Leaf) {
      Write-Host "exists" -ForegroundColor Red
      # Find the available file name
      $Iterator = 1
      $outFileNameNew = $outFileName + "_" + $Iterator + $_.Extension
      write-host "$outFileNameNew... " -ForegroundColor Yellow -NoNewline
      $testPath = Join-Path -Path $parentDirectory -ChildPath $outFileNameNew
      #write-host "$testPath" -ForegroundColor Yellow
      while (Test-Path -Path $testPath -PathType Leaf) {
        write-host "$outFileNameNew... " -ForegroundColor Yellow -NoNewline
        $Iterator = $Iterator + 1
        $outFileNameNew = $outFileName + "_" + $Iterator + $_.Extension
        $testPath = Join-Path -Path $parentDirectory -ChildPath $outFileNameNew
        write-host "exits " -ForegroundColor Red
      }
      write-host "does not exits" -ForegroundColor Red
      # Move the file to the new unique file name
      $outFileNameNewPath = $testPath
      #Write-Output "New unique file name: $outFileNameNewPath"
      Move-Item -Path $_ -Destination $outFileNameNewPath -Verbose
    }
    else {
      Write-Host "does not exist"
      Move-Item -Path $_ -Destination $outFilePath -Verbose
    }
  }
}
Write-Output "Done"

# You can run this script using the following command
# .\rename.ps1 -ErrorAction Stop