# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

Write-Output "hello"

# check if running from command line
if ((Get-CimInstance win32_process -Filter "ProcessID=$PID" | Where-Object { $_.processname -eq "pwsh.exe" -or "powershell.exe"}) | Select-Object commandline) {
    # running from command line
    Write-Output "goodbye"
}
else {
    # running as script
    Timeout /T 5
}
