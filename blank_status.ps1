# settings
$wait_ms = 512    
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

# define process name
$proc = 'POWERPNT.EXE'
$proc_name=[io.path]::GetFileNameWithoutExtension($proc)

# define file name
$ppt_name = 'blank.ppsx'
$ppt_pid3=(Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object {$_.mainWindowTitle -like "*$ppt_name*"})
Write-Host "ppt pid = $ppt_pid3"
$startCPU=($ppt_pid3).CPU[-1]

while ($($elapsedTime.TotalSeconds) -lt 10) {        
    $tempCPU=($ppt_pid3).CPU[-1]
    Write-Host -NoNewline "  CPU = $tempCPU"
    $absdiffcpu=$tempCPU-$startCPU
    $reldiffcpu=($tempCPU/$startCPU)/100        
    Write-Host -NoNewline "  CPU change = $absdiffcpu or $reldiffcpu%" 
    $dCPU=$tempCPU-$lastCPU
    Write-Host -NoNewline "  dCPU = $dCPU" 
    $lastCPU=$tempCPU    
    $elapsedTime = $(get-date) - $StartTime
    Write-Host "  elapsed time  = $($elapsedTime.TotalMilliseconds) ms"
    Start-Sleep -Milliseconds $wait_ms    
}

Write-Output "goodbye" 
Timeout /T 5