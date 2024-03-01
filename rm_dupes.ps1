$files = Get-ChildItem -Recurse | Where-Object { $_.Name -match "\(2\)" }

foreach ($inFile in $files) {
  $inPath = $inFile.DirectoryName
  $inFileDir = Split-Path -Leaf $inPath
  $inFileName = Join-Path -Path $inFileDir -ChildPath $inFile
  Write-Host "$inFileName"

  $outFile = $inFile.Name -replace ' \(2\)', ''
  $outFileName = Join-Path -Path $inFileDir -ChildPath $outFile
  Write-Host "$outFileName... " -NoNewline
  $outFileName = Join-Path -Path $inFile.Directory.FullName -ChildPath $outFile

  if (Test-Path -Path $outFileName -PathType Leaf) {
    Write-Host "already exists, " -ForegroundColor Red -NoNewline
    if ($originalFile.Length -eq $inFile.Length) {
      write-host "files have same length" -ForegroundColor Yellow
      Remove-Item -Path $inFile.FullName -Verbose
    }
    else {
      write-host "files have different lengths" -ForegroundColor Red
    }
  }
  else {
    write-host "$originalFile does not exist" -ForegroundColor Green
    Move-Item -Path $inFile.FullName -Destination $outFileName -Verbose
  }
}