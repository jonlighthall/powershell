$files = Get-ChildItem -Recurse | Where-Object { $_.Name -match ' \(2\)$' }

foreach ($file in $files) {
	$originalName = $file.Name -replace ' \(2\)$', ''
	$originalFile = Get-ChildItem -Path $file.Directory.FullName | Where-Object { $_.Name -eq $originalName }

	if ($originalFile -and $originalFile.Length -eq $file.Length) {
		Remove-Item -Path $file.FullName -Verbose
	} elseif (-not $originalFile) {
		Rename-Item -Path $file.FullName -NewName $originalName -Verbose
	}
}
