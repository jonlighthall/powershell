$loop_wait_min = 4
$blink_wait_ms = 32
$blinks_per_loop = 2
$keys = @("{CAPSLOCK}")
$nkeys = $keys.Length
$loop_wait_s = $loop_wait_min * 60
$loop_wait_ms = $loop_wait_s * 1000
$WShell = New-Object -ComObject Wscript.Shell
Write-Host "Press Ctrl-C to exit."
while ($true) {
        for ($j = 0; $j -lt ($blinks_per_loop * 2); $j++) {
            for ($i = 0; $i -lt $nkeys; $i++) {
                $WShell.sendkeys($($keys[$i]))
            }
            Start-Sleep -Milliseconds $blink_wait_ms
        }
    $this_wait = Get-Random -Minimum 0 -Maximum $loop_wait_ms
    $this_wait = $([int] $this_wait)
    Start-Sleep -Milliseconds $this_wait
}