$blink_wait_ms = 32
$blinks_per_loop = 2
$loop_wait_min = 8
$loop_wait_s = $loop_wait_min*60
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length
$WShell = New-Object -ComObject Wscript.Shell
Write-Output "Press Ctrl-C to exit."
$counter = 0
while ($true) {
    for ($j=0;$j -lt ($blinks_per_loop*2);$j++) {
        for ($i=0;$i -lt $nkeys;$i++) {
            $WShell.sendkeys("$keys[$i]")
        }
        Start-Sleep -Milliseconds $blink_wait_ms
    }
    Write-Host -NoNewline "."
    $counter++
    if (($counter % [int](60/$loop_wait_min))-eq 0) {
        Write-Host "$(Get-Date -Format HH:mm)"
    }
    Start-Sleep -Seconds $loop_wait_s
}