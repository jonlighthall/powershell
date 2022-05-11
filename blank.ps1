# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
# Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
# Install-Module PowerShellGet -AllowClobber -Force -Scope CurrentUser
# Install-Module -Name VirtualDesktop -Scope CurrentUser

Switch-Desktop -Desktop 1
$office_dir = 'C:\Program Files (x86)\Microsoft Office\Office16'
$ppt_dir = '$Env:OneDrive\Desktop'
$ppt_name = 'blank.ppsx'
Write-Output "starting presentation $ppt_name..." 
Start-Process -WorkingDirectory $office_dir -FilePath .\POWERPNT.EXE -ArgumentList "/S `"$ppt_dir\$ppt_name`""
$StartTime = $(get-date)
$check = Get-Process POWERPNT -ErrorAction SilentlyContinue
$wait_ms=100

# wait for CPU to increase before switching back
while (($check).CPU -lt 1.0) {
 {Write-Output "still loading..."}
 Start-Sleep -Milliseconds $wait_ms
 Write-Output "CPU = " ($check).CPU
 $elapsedTime = $(get-date) - $StartTime
 Write-Output "elapsed time  = $elapsedTime" 
}

# switch back to primary desktop
Start-Sleep -Milliseconds $wait_ms
Switch-Desktop -Desktop 0