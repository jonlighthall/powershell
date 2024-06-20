# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
# Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
# Install-Module PowerShellGet -AllowClobber -Force -Scope CurrentUser
# Install-Module -Name VirtualDesktop -Scope CurrentUser -Force

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

$env:PSModulePath = "${HOME}\Documents\WindowsPowerShell\Modules;" + $env:PSModulePath

# settings
$loop_wait_ms = 512
$message_wait_ms = 1250
$CPU_change = 1.2
$dCPU_thresh = 0.05
# turn debugging messages on or off
#$DebugPreference = 'Continue'

# define time
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

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
    $proc_name = [io.path]::GetFileNameWithoutExtension($proc)
}
else {
    Write-Output "not found"
    Start-Sleep -Milliseconds $message_wait_ms
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
    Start-Sleep -Milliseconds $message_wait_ms
    exit 1
}

# define file name
$ppt_name = 'blank.ppsx'
Write-Host -NoNewline "$ppt_dir\$ppt_name... "
if (Test-Path -Path $ppt_dir\$ppt_name ) {
    Write-Output "found"
    # get PID
    $ppt_pid2 = $((Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object { $_.mainWindowTitle -like "*$ppt_name*" }).Id)
    # test PID
    if ($ppt_pid2 -is [int]) {
        Write-Debug "ppt pid = $ppt_pid2 (int)"
    }
    else {
        Write-Debug "ppt pid = not int : assume not open"
    }
    if ($null -eq $ppt_pid2) {
        Write-Debug "ppt pid = null $ppt_pid2   : assume not open"
        Switch-Desktop -Desktop 1
        # open ppt
        Write-Output "starting presentation $ppt_name..."
        Start-Process -WorkingDirectory $office_dir -FilePath .\$proc -ArgumentList "/S `"$ppt_dir\$ppt_name`""

        $open = $false
        $finished = $false

        # define file location
        $ps_dir = $("${HOME}\Documents\powershell")
        Write-Host -NoNewline "$ps_dir... "
        # test path
        if (Test-Path -Path $ps_dir ) {
            Write-Output "found"
            $ps_name = "blank_status.ps1"
            Write-Host -NoNewline "$ps_dir\$ps_name... "
            # test file
            if (Test-Path -Path $ps_dir\$ps_name ) {
                Write-Output "found"
                Start-Process -WorkingDirectory "${ps_dir}" powershell -ArgumentList { ./blank_status.ps1 }
            }
            else {
                Write-Output "not found"
                read-host "Press ENTER to continue..."
            }
        }
        else {
            Write-Output "not found"
            read-host "Press ENTER to continue..."
        }
    }
    else {
        Write-Debug "ppt pid = $ppt_pid2 (not null)"
        $open = $true
        Write-Output "$ppt_name already open"
        $finished = $true
    }
    # check if open
    if ($open -eq $false) {
        Write-Host -NoNewline "  opening $ppt_name... "
        Write-Debug ""
        while ($open -eq $false ) {
            Write-Debug "still opening..."
            $ppt_pid3 = (Get-Process $proc_name -ErrorAction SilentlyContinue | Where-Object { $_.mainWindowTitle -like "*$ppt_name*" })
            if (($ppt_pid3).Id -is [int]) {
                Write-Debug "  ppt pid = $(($ppt_pid3).Id)"
                $open = $true
                Start-Sleep -Milliseconds $loop_wait_ms
                $startCPU = ($ppt_pid3).CPU[-1]
                Write-Debug "  starting CPU = $startCPU"
                $lastCPU = $startCPU
            }
            else {
                Write-Debug "  ppt pid = null $(($ppt_pid3).Id)"
            }
            $elapsedTime = $(get-date) - $StartTime
            Write-Debug "  elapsed time  = $elapsedTime"
        }
        Write-Output "opened, elapsed time  = $elapsedTime"

        Write-Host -NoNewline "  loading $ppt_name... "
        Write-Debug ""
        Write-Debug "open = $open"
        $finished = $false
        Write-Debug "finished = $finished"

        while (($finished -eq $false ) -and ($($elapsedTime.TotalSeconds) -lt 10)) {
            Write-Debug "still loading..."
            Start-Sleep -Milliseconds $loop_wait_ms
            $tempCPU = ($ppt_pid3).CPU[-1]
            Write-Debug "  CPU = $tempCPU"
            $absdiffcpu = $tempCPU - $startCPU
            $reldiffcpu = ($tempCPU / $startCPU) / 100
            Write-Debug "  CPU change = $absdiffcpu or $reldiffcpu%"
            $dCPU = $tempCPU - $lastCPU
            Write-Debug "  dCPU = $dCPU"
            if ($dCPU -lt $dCPU_thresh) {
                Write-Host "  dCPU < " $dCPU_thresh
                break
            }
            else {
                Write-Host "  dCPU > " $dCPU_thresh
            }

            $lastCPU = $tempCPU
            Write-Debug "  CPU change is..."
            if (($absdiffcpu -gt $CPU_change) -and ($dCPU -lt $dCPU_thresh)) {
                Write-Debug "    pass"
                $finished = $true
            }
            else {
                Write-Debug "    fail"
            }
            $elapsedTime = $(get-date) - $StartTime
            Write-Debug "  elapsed time  = $elapsedTime"
            Write-Debug "  elapsed time  = $($elapsedTime.TotalSeconds) s"
            Write-Debug "  elapsed time  = $($elapsedTime.TotalMilliseconds) ms"
        }
        Write-Output "loaded, elapsed time  = $elapsedTime"

        # switch back to primary desktop
        Write-Host -NoNewline "waiting $loop_wait_ms... "
        Start-Sleep -Milliseconds $loop_wait_ms
        Write-Output "done"
        #Switch-Desktop -Desktop 0
    }

    $DebugPreference = 'SilentlyContinue'
    Write-Output "goodbye"
    Start-Sleep -Milliseconds $message_wait_ms

}
else {
    Write-Output "not found"
    Start-Sleep -Milliseconds $message_wait_ms
    exit 1
}