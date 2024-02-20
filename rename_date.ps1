$Shell = New-Object -ComObject shell.application

# Iterate through each file
Get-ChildItem -Recurse -file *.jpg,*jpeg,*.mp4,*.mov,*.heic -ErrorAction Stop | ForEach{
    Write-host
    
    Write-Output "checking $_.Name"
    
    
    
    
    

    $Folder = $Shell.NameSpace($_.DirectoryName)
    $File = $Folder.ParseName($_.Name)
    

    # Find the available property
    $Property = $Folder.GetDetailsOf($File,12)
    if (-not $Property) {
        $Property = $Folder.GetDetailsOf($File,3)
        if (-not $Property) {
            $Property = $Folder.GetDetailsOf($File,4)
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
    
    $outPath = $parentDirectory + "\" + $DateTaken2
    
    write-host $inPath $outPath
    
# Check if inPath and outPath are the same
if ($inPath -eq $outPath) {
    Write-Output "inPath and outPath are the same"
} else {
    Write-Output "inPath and outPath are different"
    Write-Output "Moving $_.Name to $outPath"
    
    #Move-Item -Path $inPath -Destination $outPath -Verbose
}
    
    

    # Find the available file name
    $FileName = $DateTaken + "_" + $Iterator
    $Path = $_.DirectoryName + "\" + $FileName + $_.Extension
    while (Test-Path -Path $Path -PathType Leaf) {
        $Iterator = $Iterator + 1
        $FileName = $DateTaken + "_" + $Iterator
        $Path = $_.DirectoryName + "\" + $FileName + $_.Extension
    }

    # Rename file
    Write-Output $_.Name"=>"$FileName
    #Rename-Item $_.FullName ($FileName + $_.Extension)
}

# You can run this script using the following command
# .\rename.ps1 -ErrorAction Stop