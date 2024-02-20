$Shell = New-Object -ComObject shell.application

$DirectoryName = $_.DirectoryName
Write-Host "Directory Name: $DirectoryName"

# Iterate through each file
Get-ChildItem -Recurse -file *.jpg, *jpeg, *.mp4, *.mov, *.heic -ErrorAction Stop | ForEach-Object {    
    $inFileName = $_.Name
    Write-Host "$inFileName"
    
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
    
    # Define output directory based on date taken
    $inPath = $_.DirectoryName     
    $parentDirectory = Split-Path -Parent $inPath        
    $outPath = Join-Path -Path $parentDirectory -ChildPath $DateTaken2           
    
    # Check if inPath and outPath are the same
    if ( -not ($inPath -eq $outPath)) {        
        write-host $inPath
        write-host $outPath
        
        # Check if outPath exists, and if not, create the directory
        if (-not (Test-Path -Path $outPath -PathType Container)) {
            New-Item -ItemType Directory -Path $outPath -Verbose
        }        
        $outFileName = Join-Path -Path $outPath -ChildPath $inFileName        
        Write-Host $inFileName
        Write-Host $outFileName        
        Write-Output "Moving $_ to $outFileName"   
        
        # Check if outFileName exists
        if (Test-Path -Path $outFileName -PathType Leaf) {
            Write-Output "outFileName already exists"
            # Check if outFileName exists
            if (Test-Path -Path $outFileName -PathType Leaf) {
                Write-Output "outFileName already exists"
                # Find the available file name
                $Iterator = 1
                $outFileNameNew = $outFileName + "_" + $Iterator
                $Path = $_.DirectoryName + "\" + $outFileNameNew + $_.Extension
                while (Test-Path -Path $Path -PathType Leaf) {
                    $Iterator = $Iterator + 1
                    $outFileNameNew = $DateTaken + "_" + $Iterator
                    $Path = $_.DirectoryName + "\" + $outFileNameNew
                    + $_.Extension
                }
                # Move the file to the new unique file name
                $outFileNameNewPath = $Path
                Write-Output "New unique file name: $outFileNameNewPath"
                Move-Item -Path $_ -Destination $outFileNameNewPath -Verbose
            }
        }
        else {
            Write-Output "outFileName does not exist"
            Move-Item -Path $_ -Destination $outFileName -Verbose
        }
    }
}
Write-Output "Done"

# You can run this script using the following command
# .\rename.ps1 -ErrorAction Stop