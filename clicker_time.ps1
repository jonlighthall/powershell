$WShell = New-Object -ComObject Wscript.Shell
Write-Host "Press Ctrl-C to exit."
while ($true) {
    if ((Get-Date).Hour -ge 11) {
        write-host "$((Get-Date).Hour):$((Get-Date).Minute) done"
        break
    }
    1..4 | ForEach-Object {
        $WShell.sendkeys("{CAPSLOCK}")
        Start-Sleep -Milliseconds 32
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 4*60*1000)
}