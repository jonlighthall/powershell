$blink_wait_ms = 200
$WShell = New-Object -ComObject Wscript.Shell
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length
Write-Output "$keys has length $nkeys"
Write-Output "start for loops"
for ($j=0;$j -lt 10;$j++) {
    Write-Output "outer loop $j"
    for ($i=0;$i -lt $nkeys;$i++) {
        Write-Output "innter loop $i"
        Write-Output "$i "$keys[$i]
        $WShell.sendkeys("$keys[$i]")
        Start-Sleep -Milliseconds $blink_wait_ms
        $WShell.sendkeys("$keys[$i]")
        Start-Sleep -Milliseconds $blink_wait_ms
    }
}
Write-Output "start while loop"
Write-Output "Press Ctrl-C to exit."
while ($true) {
    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Milliseconds 100
    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 2
}