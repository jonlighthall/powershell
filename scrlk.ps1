$blink_wait_ms = 200
$WShell = New-Object -ComObject Wscript.Shell
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length
Write-Output "$keys has length $nkeys"
Write-Output "start for loops"
for ($i=0;$i -lt $nkeys;$i++) {
    Write-Output "$i $($keys[$i])"
}
Write-Output "start while loop"
Write-Output "Press Ctrl-C to exit."
while ($true) {
    for ($j=0;$j -lt 10;$j++) {
        for ($i=0;$i -lt $nkeys;$i++) {
            $WShell.sendkeys("$keys[$i]")
            Start-Sleep -Milliseconds $blink_wait_ms
            $WShell.sendkeys("$keys[$i]")
            Start-Sleep -Milliseconds $blink_wait_ms
        }
    }
    Start-Sleep -Seconds 2
}
