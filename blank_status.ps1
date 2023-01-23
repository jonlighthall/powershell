# settings
$udpate_wait_ms = 256
$loop_wait_ms = 512
$message_wait_ms = 1500
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

# define process name
$proc = 'POWERPNT.EXE'
$proc_name=[io.path]::GetFileNameWithoutExtension($proc)

# define file name
$ppt_name = 'blank.ppsx'
$lastTime = $elapsedTime
Write-Host "opening $ppt_name..."
while ($($elapsedTime.TotalSeconds) -lt 10) {
    $elapsedTime = $(get-date) - $StartTime
    if (($elapsedTime-$lastTime).TotalMilliseconds -gt $udpate_wait_ms) {
        Write-Host "  elapsed time  = $($elapsedTime.TotalMilliseconds) ms"
    }

    #get PID
    $ppt_proc=$(Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object {$_.mainWindowTitle -like "*$ppt_name*"})
    $ppt_pid3=$(($ppt_proc).Id)

    # test PID
    if ($null -eq $ppt_pid3) {
        if (($elapsedTime-$lastTime).TotalMilliseconds -gt $udpate_wait_ms) {
            Write-Host  "  $ppt_name PID is null"
            $lastTime = $elapsedTime
        }
        continue
    } else {
        Write-Host  "$ppt_name PID = " ($ppt_pid3)
        $startCPU=($ppt_proc).CPU[-1]
        $dCPU=1
        while ($dCPU -gt 0) {
            $tempCPU=($ppt_proc).CPU[-1]
            Write-Host -NoNewline "  CPU = $tempCPU"
            $absdiffcpu=$tempCPU-$startCPU
            $reldiffcpu=($tempCPU/$startCPU)/100
            Write-Host -NoNewline "  CPU change = $absdiffcpu or $reldiffcpu%"
            $dCPU=$tempCPU-$lastCPU
            Write-Host -NoNewline "  dCPU = $dCPU"
            $lastCPU=$tempCPU
            $elapsedTime = $(get-date) - $StartTime
            Write-Host "  elapsed time  = $($elapsedTime.TotalMilliseconds) ms"
            Start-Sleep -Milliseconds $loop_wait_ms
        }
        Write-Output "done"
        Start-Sleep -Milliseconds $message_wait_ms
        break
    }
}

Write-Output "goodbye"
Start-Sleep -Milliseconds $message_wait_ms
# switch back to primary desktop
Switch-Desktop -Desktop 0