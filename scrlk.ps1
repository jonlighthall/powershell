$blink_wait_ms = 128

Write-Output "Press Ctrl-C to exit."

$WShell = New-Object -ComObject Wscript.Shell

$keys=@("CAPSLOCK","SCROLLLOCK")
$nkeys=$keys.Length
echo "$keys has length $nkeys"

for ($i=0;$i -lt $nkeys;$i++) {
echo "$i "$keys[$i]
#$keys[$i]

$blink_wait_ms
}



while ($true) {


    for ($i=0;$i -lt $nkeys;$i++) {
        echo "$i "$keys[$i]
        #$keys[$i]

        $WShell.sendkeys("$keys[$i]")
        Start-Sleep -Milliseconds $blink_wait_ms
        $WShell.sendkeys("$keys[$i]")


        }


    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Milliseconds 100
    $WShell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 2
}