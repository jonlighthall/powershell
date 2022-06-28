# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
# Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
# Install-Module PowerShellGet -AllowClobber -Force -Scope CurrentUser
# Install-Module -Name VirtualDesktop -Scope CurrentUser -Force

# settings
$wait_ms = 512    
$CPU_change = 1.2

# define executable directory
$office_dir = 'C:\Program Files (x86)\Microsoft Office\Office16'
Write-Host -NoNewline "$office_dir... "
If (Test-Path -Path $office_dir ) {
    Write-Output "found"
}
else { 
    Write-Output "not found"
    exit 1
}

# define process name
$proc = 'POWERPNT.EXE'
Write-Host -NoNewline "$office_dir\$proc... "
If (Test-Path -Path $office_dir\$proc ) {
    Write-Output "found"
    $proc_name=[io.path]::GetFileNameWithoutExtension($proc)
}
else { 
    Write-Output "not found"
    exit 1
}

# define file location
$ppt_dir = $("${Env:OneDrive}\Desktop")
Write-Host -NoNewline "$ppt_dir... "
if (Test-Path -Path $ppt_dir ) {
    Write-Output "found"
}
else {    
    Write-Output "not found"
    exit 1
}

# define file name
$ppt_name = 'blank.ppsx'
Write-Host -NoNewline "$ppt_dir\$ppt_name... "
if (Test-Path -Path  $ppt_dir\$ppt_name ) {
    Write-Output "found"    
    $DebugPreference = 'Continue'    
    $ppt_pid2=$((Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object {$_.mainWindowTitle -like "*$ppt_name*"}).Id)    
    if ($ppt_pid2 -is [int]) {
        Write-Debug "ppt pid = $ppt_pid2 (int)"
    } else {
        Write-Debug "ppt pid = not int"        
    }    
    if ($null -eq $ppt_pid2) {
        Write-Debug "ppt pid = null $ppt_pid2"
        Switch-Desktop -Desktop 1
        # open ppt
        Write-Output "starting presentation $ppt_name..."         
        Start-Process -WorkingDirectory $office_dir -FilePath .\$proc -ArgumentList "/S `"$ppt_dir\$ppt_name`""
        $StartTime = $(get-date)
        $open = $false
        $finished=$false
    } else {
        Write-Debug "ppt pid = $ppt_pid2 (not null)"
        $open=$true
        Write-Output "$ppt_name already open"
        $finished=$true
    }
    if ($open -eq $false) {
    Write-Host -NoNewline "  opening $ppt_name... "
    Write-Debug "" 
        while ($open -eq $false ) {
            Write-Debug "still opening..." 
            #Start-Sleep -Milliseconds $wait_ms             
            $ppt_pid3=(Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object {$_.mainWindowTitle -like "*$ppt_nanme*"})                            
            if (($ppt_pid3).Id -is [int]) {
                Write-Debug "  ppt pid = $(($ppt_pid3).Id)"
                $open=$true
                Start-Sleep -Milliseconds $wait_ms  
                $startCPU=($ppt_pid3).CPU[-1]
                Write-Debug "  starting CPU = $startCPU"         
                $lastCPU=$startCPU
            } else {
                Write-Debug "  ppt pid = null $(($ppt_pid3).Id)"            
            }      
            $elapsedTime = $(get-date) - $StartTime
            Write-Debug "  elapsed time  = $elapsedTime" 
        }
    Write-Output "opened, elapsed time  = $elapsedTime"     
    
    Write-Host -NoNewline "  loading $ppt_name... "
    Write-Debug "" 
    Write-Debug "open = $open" 
    Write-Debug "finished = $finished" 
    $finished=$false
    Write-Debug "finished = $finished" 

    while (($finished -eq $false ) -and ($($elapsedTime.TotalSeconds) -lt 10)) {
        Write-Debug "still loading..." 
        Start-Sleep -Milliseconds $wait_ms     
        $tempCPU=($ppt_pid3).CPU[-1]
        Write-Debug "  CPU = $tempCPU"
        $absdiffcpu=$tempCPU-$startCPU
        $reldiffcpu=($tempCPU/$startCPU)/100        
        Write-Debug "  CPU change = $absdiffcpu or $reldiffcpu%"                
        $dCPU=$tempCPU-$lastCPU
        Write-Debug "  dCPU = $dCPU" 
        $lastCPU=$tempCPU
        Write-Debug  "  CPU change is "
        if (($absdiffcpu -gt $CPU_change) -and ($dCPU -lt 0.05)) {
            Write-Debug "pass"      
            $finished=$true
        } else {
            Write-Debug "fail"            
                    }
        $elapsedTime = $(get-date) - $StartTime
        Write-Debug "  elapsed time  = $elapsedTime" 
        Write-Debug "  elapsed time  = $($elapsedTime.TotalSeconds) s" 
        Write-Debug "  elapsed time  = $($elapsedTime.TotalMilliseconds) ms"         
    }
    Write-Output "loaded, elapsed time  = $elapsedTime" 

    # switch back to primary desktop
    Write-Host -NoNewline "waiting $wait_ms... "
    Start-Sleep -Milliseconds $wait_ms
    Switch-Desktop -Desktop 0
    Write-Output "done"
    }
    
    $DebugPreference = 'SilentlyContinue'
    Write-Output "goodbye" 
    Timeout /T 5
}
else {    
    Write-Output "not found"
    exit 1
}