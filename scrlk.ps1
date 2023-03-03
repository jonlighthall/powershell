
# MouseJiggler Powershell Script
# Written by AndrewDavis
# https://gist.github.com/AndrewDavis

Clear-Host
Write-Output "Keep-alive with Scroll Lock..."

$WShell = New-Object -ComObject Wscript.Shell

while ($true)
{
$WShell.sendkeys("{SCROLLLOCK}")
Start-Sleep -Milliseconds 100
$WShell.sendkeys("{SCROLLLOCK}")
Start-Sleep -Seconds 240
}