# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

for ($i = 1; $i -le 1000; $i++) {
  Write-Host $i
}