# blink settings
$blink_wait_ms = 32
$blinks_per_loop = 2
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length

# loop settings
$loop_wait_min = 8
$loop_wait_s = $loop_wait_min*60
$loops_per_hour = $([int](60/$loop_wait_min))

# print settings
$line_lim=10
if ($loops_per_hour -gt $line_lim) {
    $ndots=$line_lim
}
else {
    $ndots=$loops_per_hour
}
Write-Output "Press Ctrl-C to exit."
$counter = 0

$WShell = New-Object -ComObject Wscript.Shell
while ($true) {
    for ($j=0;$j -lt ($blinks_per_loop*2);$j++) {
        for ($i=0;$i -lt $nkeys;$i++) {
            $WShell.sendkeys("$keys[$i]")
        }
        Start-Sleep -Milliseconds $blink_wait_ms
    }
    if (($counter -gt 0) -and (($counter % $ndots) -eq 0)) {
        Write-Host " $(Get-Date -Format HH:mm)"
    }
    Write-Host -NoNewline "."	
    $counter++
    Start-Sleep -Seconds $loop_wait_s
}