$WShell = New-Object -ComObject Wscript.Shell
Write-Host "Press Ctrl-C to exit."
while ($true) {
    # enter the time you want the script to stop (24-hour format)
    if ((Get-Date).Hour -ge 18) {
        write-host "$((Get-Date).Hour):$((Get-Date).Minute) done"
        break
    }
    # the following loop will toggle the caps lock key 4 times, making the
    # indicator light blink twice
    1..4 | ForEach-Object {
        $WShell.sendkeys("{CAPSLOCK}")
        Start-Sleep -Milliseconds 32
    }
    # the script will sleep for a random amount of time between 0 and 4 minutes
    Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 4*60*1000)
}