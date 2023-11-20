# this is a PowerShell script

# Must run in elevated prompt to make link

# Must first run the following command before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

## Copy and link from OneDrive
# PowerShell history

$local = 'C:\Users\jonli\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt'
$cloud = 'C:\Users\jonli\OneDrive\Documents\ConsoleHost_history.txt'

Write-Output "test local history..."
if (Test-Path -Path $local) {
	Write-Output "$local found"
	Write-Output "test cloud history..."
	if (Test-Path -Path $cloud) {
		Write-Output "$cloud found"
		Write-Output "proceeding with append, delete, and link..."
	      
		Write-Output "appending local copy with cloud copy..."
		Add-Content -Path $cloud -Value $local

		Write-Output "removing local copy"
		$dir = [io.path]::GetDirectoryName($local)
		$fname = [io.path]::GetFileNameWithoutExtension($local)
		$ext = [io.path]::GetExtension($local)
		Move-Item -v $local $dir\${fname}_$(get-date -f yyyy-MM-dd-hhmm)$ext

		Write-Output "creating symbolic link"
		cmd /c mklink $local $cloud
	      
	}    
	else {
		Write-Output "$cloud not found"
		Write-Output "no history to link to`nexiting"
	}	   
}	   
else {  
	Write-Output "$local not found"
}
