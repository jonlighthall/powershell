# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

# settings
$update_wait_ms = 256
$loop_wait_ms = 512
$message_wait_ms = 1500

# define time
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

# define process name
$proc = 'POWERPNT.EXE'
$proc_name = [io.path]::GetFileNameWithoutExtension($proc)

# define file name
$ppt_name = 'blank.ppsx'
$lastTime = $elapsedTime
Write-Host "opening $ppt_name..."
while ($($elapsedTime.TotalSeconds) -lt 32) {
    $elapsedTime = $(get-date) - $StartTime
    if (($elapsedTime - $lastTime).TotalMilliseconds -gt $update_wait_ms) {
        Write-Host "  elapsed time  = $("{0,8:n1}" -f $($elapsedTime.TotalMilliseconds)) ms"
    }

    #get PID
    $ppt_proc = $(Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object { $_.mainWindowTitle -like "*$ppt_name*" })
    $ppt_pid3 = $(($ppt_proc).Id)

    # test PID
    if ($null -eq $ppt_pid3) {
        if (($elapsedTime - $lastTime).TotalMilliseconds -gt $update_wait_ms) {
            Write-Host  -NoNewline "  $ppt_name PID is null"
            $lastTime = $elapsedTime
        }
        continue
    }
    else {
        Write-Host  "$ppt_name PID = " ($ppt_pid3)
        $startCPU = ($ppt_proc).CPU[-1]
        $dCPU = 1
        while ($dCPU -gt 0) {
            $tempCPU = ($ppt_proc).CPU[-1]
            Write-Host -NoNewline "  CPU = $("{0:n2}" -f $tempCPU)"
            $absdiffcpu = $tempCPU - $startCPU            
            $reldiffcpu = ($absdiffcpu / $startCPU)
            Write-Host -NoNewline "  CPU change = $("{0:n2}" -f $absdiffcpu) or $("{0,5:p1}" -f $reldiffcpu)"
            $dCPU = $tempCPU - $lastCPU
            Write-Host -NoNewline "  dCPU = $("{0:n2}" -f $dCPU)"
            $lastCPU = $tempCPU
            $elapsedTime = $(get-date) - $StartTime
            Write-Host "  elapsed time  = $("{0,8:n1}" -f $($elapsedTime.TotalMilliseconds)) ms"
            Start-Sleep -Milliseconds $loop_wait_ms
        }
        Write-Output "done"
        Start-Sleep -Milliseconds $message_wait_ms
        break
    }
}
if ($null -eq $ppt_pid3) {
    Write-Output "timeout"
    Start-Sleep -Milliseconds $message_wait_ms
}
Write-Output "goodbye"
Start-Sleep -Milliseconds $message_wait_ms
# switch back to primary desktop
Switch-Desktop -Desktop 0