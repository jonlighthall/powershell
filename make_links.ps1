# this is a PowerShell script

# Must run in elevated prompt to make link

# Must first run the following command before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

$ErrorActionPreference = "Stop"

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running " -NoNewline
Write-Host "$src_path\$src_name" -NoNewline -ForegroundColor Yellow
Write-Host "..."

## Copy and link from OneDrive
# PowerShell history

# define target (source)
# specify the path to the shared history file in OneDrive
$cloud = 'C:\Users\jonli\OneDrive\Documents\ConsoleHost_history.txt'
$target = (Get-Item $cloud)

# define link (destination)
# specify the path to the Console Host history file
$local = 'C:\Users\jonli\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt'
$link = (Get-Item $local)

# check if the source file exists
Write-Host "test cloud history..."
if (Test-Path -Path $target) {
	Write-Host "   $target found"
	Write-Host "proceeding..."
}
else {
	Write-Host "   $target not found" -ForegroundColor Red
	Write-Host "   no history to link to`nexiting"
	exit 1
}

Write-Host "test local history..."
$do_append = $false
if (Test-Path -Path $local) {
	Write-Host "   $local found"
	$do_append = $true

	Write-Host "   $link is... " -NoNewline
	$do_link = $false

	if ($link.LinkType -eq "SymbolicLink") {
		Write-Host "a link "
		Write-Host "   and points to... " -NoNewline
		$linkTarget = (Get-Item -Path $local).Target
		if ($linkTarget -eq $cloud) {
			Write-Host "$cloud"
			$do_append = $false
		}
		else {
			Write-Host "something else"
			write-host "$linkTarget" -ForegroundColor Red
			$do_link = $true
		}
	}
	else {
		Write-Host " not a link"
		$do_link = $true
	}
}
else {
	Write-Host "$local not found"
	# check if the parent directory of $local exists
	$local_parent = Split-Path -Parent $local
	if (-not (Test-Path -Path $local_parent)) {
		Write-Host "Parent directory does not exist: $local_parent"
		exit 1
	}
	else {
		Write-Host "Parent directory exists: $local_parent"
		$do_link = $true
	}
}

if ($do_link) {
	if ($do_append) {
		Write-Host "   proceeding with append, delete, and link..."
		Write-Host "      appending local copy with cloud copy..."
		Add-Content -Path $cloud -Value $local

		Write-Host "      renaming local copy"
		$dir = [io.path]::GetDirectoryName($local)
		$fname = [io.path]::GetFileNameWithoutExtension($local)
		$ext = [io.path]::GetExtension($local)
		Move-Item -v $local $dir\${fname}_$(get-date -f yyyy-MM-dd-hhmm)$ext
	}
	else {
		Write-Host "   no appending to do"
		Write-Host "   proceeding with link..."
	}
	Write-Host "      creating symbolic link"
	cmd /c mklink $local $cloud
}
else {
	Write-Host "   no linking to do"
}

write-host "done"