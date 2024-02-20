$files = Get-ChildItem -Recurse | Where-Object { $_.Name -match "\(2\)" }

foreach ($file in $files) {
	$originalName = $file.Name -replace ' \(2\)', ''
	$originalFile = Get-ChildItem -Path $file.Directory.FullName | Where-Object { $_.Name -eq $originalName }
	Write-Output $file.Name
	Write-Output $originalName
	#Write-Output $originalFile

	if ($originalFile) {
		write-host "$originalFile exists"
		if ($originalFile.Length -eq $file.Length) {
			write-host "files have same length"
		}
		else {
			write-host "files have different length"
		}
	}
	else {
		write-host "$originalFile does not exist"
	}
}