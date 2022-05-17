# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
# Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
# Install-Module PowerShellGet -AllowClobber -Force -Scope CurrentUser
# Install-Module -Name VirtualDesktop -Scope CurrentUser -Force

$office_dir = 'C:\Program Files (x86)\Microsoft Office\Office16'
Write-Host -NoNewline "$office_dir... "
If (Test-Path -Path $office_dir ) {
    Write-Output "found"
}
else { 
    Write-Output "not found"
    exit 1
}
$proc = 'POWERPNT.EXE'
Write-Host -NoNewline "$office_dir\$proc... "
If (Test-Path -Path $office_dir\$proc ) {
    Write-Output "found"
}
else { 
    Write-Output "not found"
    exit 1
}

$ppt_dir = $("${Env:OneDrive}\Desktop")
Write-Host -NoNewline "$ppt_dir... "
if (Test-Path -Path $ppt_dir ) {
    Write-Output "found"
}
else {    
    Write-Output "not found"
    exit 1
}

$ppt_name = 'blank.ppsx'
Write-Host -NoNewline "$ppt_dir\$ppt_name... "
if (Test-Path -Path  $ppt_dir\$ppt_name ) {
    Write-Output "found"
    Write-Output "starting presentation $ppt_name..." 
    $wait_ms = 100
    Switch-Desktop -Desktop 1

    # open ppt
    Start-Process -WorkingDirectory $office_dir -FilePath .\$proc -ArgumentList "/S `"$ppt_dir\$ppt_name`""

    # wait for CPU to increase before switching back
    $StartTime = $(get-date)
    $check = Get-Process POWERPNT -ErrorAction SilentlyContinue
    $startCPU=($check).CPU[-1]
    Write-Output "starting CPU = $startCPU"
    while ((($check).CPU[-1] -lt ($startCPU + 1.0))){
        Write-Output "still loading..." 
        Start-Sleep -Milliseconds $wait_ms
        Write-Output "  CPU = $(($check).CPU[-1])"
        $elapsedTime = $(get-date) - $StartTime
        Write-Output "  elapsed time  = $elapsedTime" 
    } 
    
    # switch back to primary desktop
    Start-Sleep -Milliseconds $wait_ms
    Switch-Desktop -Desktop 0

    Write-Output "$ppt_name loaded" 
    Write-Output "goodbye" 
    Start-Sleep 3
}
else {    
    Write-Output "not found"
    exit 1
}