$WShell = New-Object -ComObject Wscript.Shell
Write-Host "Press Ctrl-C to exit."
while ($true) {
    1..4 | ForEach-Object {
        $WShell.sendkeys("{CAPSLOCK}")
        Start-Sleep -Milliseconds 32
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 240000)
}