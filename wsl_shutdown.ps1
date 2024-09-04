Write-Host "`ncurrently installed WSL distros:"
wsl --list --verbose
Write-Host -NoNewline "`nshutting down WSL..."
wsl --shutdown
Write-Host "done"