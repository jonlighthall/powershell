$loop_wait_min = 4
$blink_wait_ms = 32
$blinks_per_loop = 2
$keys = @("{CAPSLOCK}")
$loop_wait_ms = $loop_wait_min * 60 * 1000
$WShell = New-Object -ComObject Wscript.Shell
Write-Host "Press Ctrl-C to exit."
while ($true) {
    1..($blinks_per_loop * 2) | ForEach-Object {
        $keys | ForEach-Object { $WShell.sendkeys($_) }
        Start-Sleep -Milliseconds $blink_wait_ms
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum $loop_wait_ms)
}