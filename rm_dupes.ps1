Get-ChildItem -Recurse | ForEach-Object {
		$NewName = $_.Name -replace ' \(1\)',''
		if (-not ($_.name -eq $newname)){
			   Rename-Item -Path $_.fullname -newname ($newName) }} -Verbose; Get-ChildItem '* (1).*'| Remove-Item -Verbose;
