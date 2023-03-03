$blink_wait_ms = 32
$blinks_per_loop = 4
$loop_wait_min = 3/60
$loop_wait_s = $loop_wait_min*60
$WShell = New-Object -ComObject Wscript.Shell
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length
Write-Output "Press Ctrl-C to exit."
while ($true) {
    for ($j=0;$j -lt ($blinks_per_loop*2);$j++) {
        for ($i=0;$i -lt $nkeys;$i++) {
            $WShell.sendkeys("$keys[$i]")
        }
        Start-Sleep -Milliseconds $blink_wait_ms
    }
    Start-Sleep -Seconds $loop_wait_s
}