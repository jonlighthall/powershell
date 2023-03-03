Write-Output "Press Ctrl-C to exit."

$WShell = New-Object -ComObject Wscript.Shell

while ($true) {
    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Milliseconds 100
    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 2
}