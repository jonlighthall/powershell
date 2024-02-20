$Shell = New-Object -ComObject shell.application

$DirectoryName = $_.DirectoryName
Write-Host "Directory Name: $DirectoryName"

# Iterate through each file
Get-ChildItem -Recurse -file *.jpg, *jpeg, *.mp4, *.mov, *.heic -ErrorAction Stop | ForEach {
    Write-host
    
    $inFileName = $_.Name
    write-host "File Name: $inFileName"
    
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
    $DateTaken = $DateTime.ToString("yyyyMMdd_HHmm")
    $DateTaken2 = $DateTime.ToString("yyyy-MM-dd")
    
    write-host $DateTaken2
    
    $inPath = $_.DirectoryName     
    $parentDirectory = Split-Path -Parent $inPath        
    $outPath = Join-Path -Path $parentDirectory -ChildPath $DateTaken2           
    
    write-host $inPath
    write-host $outPath
    
    # Check if inPath and outPath are the same
    if ($inPath -eq $outPath) {
        Write-Output "inPath and outPath are the same"
    }
    else {
        Write-Output "inPath and outPath are different"
        
        
        
        
        
        
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
        
                $Iterator = 1

                # Find the available file name
                $outFileNameNew = $outFileName + "_" + $Iterator
                $Path = $_.DirectoryName + "\" + $outFileNameNew + $_.Extension
                while (Test-Path -Path $Path -PathType Leaf) {
                    $Iterator = $Iterator + 1
                    $outFileNameNew = $DateTaken + "_" + $Iterator
                    $Path = $_.DirectoryName + "\" + $outFileNameNew
                    + $_.Extension
                }

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
    
    $Iterator = 1

    # Find the available file name
    $outFileNameNe = $DateTaken + "_" + $Iterator
    $outFileNameNe = $DateTaken
    $Path = $_.DirectoryName + "\" + $outFileNameNe + $_.Extension
    while (Test-Path -Path $Path -PathType Leaf) {
        $Iterator = $Iterator + 1
        $outFileNameNew = $DateTaken + "_" + $Iterator
        $Path = $_.DirectoryName + "\" + $outFileNameNew + $_.Extension
    }

    # Rename file
    Write-Output $_.Name"=>"$outFileNameNe
    #Rename-Item $_.FullName ($outFileNameNe + $_.Extension)
}

# You can run this script using the following command
# .\rename.ps1 -ErrorAction Stop