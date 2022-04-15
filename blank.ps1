# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
# Install-Module -Name VirtualDesktop -Scope CurrentUser

Switch-Desktop -Desktop 1
$office_dir = 'C:\Program Files (x86)\Microsoft Office\Office16'
$ppt_dir = 'C:\Users\jlighthall\OneDrive\Desktop'
$ppt_name = 'blank.ppsx'
Write-Output "starting presentation $ppt_name..." 
Start-Process -WorkingDirectory $office_dir -FilePath .\POWERPNT.EXE -ArgumentList "/S `"$ppt_dir\$ppt_name`"" 
Start-Sleep -Milliseconds 1000 # add wait to ensure ppt opens on other desktop
Switch-Desktop -Desktop 0