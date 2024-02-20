$files = Get-ChildItem -Recurse | Where-Object { $_.Name -match "\(2\)" }

foreach ($file in $files) {
	Write-Host " input file name: $file"
	$originalName = $file.Name -replace ' \(2\)', ''
	Write-Host "output file name: $originalName"

	Write-Host " input file:" $file.FullName
	$outFileName= Join-Path -Path $file.Directory.FullName -ChildPath $originalName
	Write-Host "output file: $outFileName... " -NoNewline

	if (Test-Path -Path $outFileName -PathType Leaf) {
		Write-Host "already exists, " -ForegroundColor Red -NoNewline
		if ($originalFile.Length -eq $file.Length) {
			write-host "files have same length" -ForegroundColor Yellow
			Remove-Item -Path $file.FullName -Verbose
		}
		else {
			write-host "files have different lengths" -ForegroundColor Red
		}
	}
	else {
		write-host "$originalFile does not exist" -ForegroundColor Green
		Move-Item -Path $file.FullName -Destination $outFileName -Verbose
	}
}