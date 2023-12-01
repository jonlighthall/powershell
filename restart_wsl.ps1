# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

wsl -l -v

Write-Output "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Shutdown WSL
Write-Output "shutting down WSL..."
wsl --shutdown

# Restart WSL
Write-Output "restarting WSL..."
Start-Process wsl ~

Write-Output "goodbye" 