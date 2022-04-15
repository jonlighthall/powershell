# The following commands must be run  before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
# Install-Module -Name VirtualDesktop -Scope CurrentUser

Switch-Desktop -Desktop 1
Write-Output "starting presentation..." 
Start-Process -WorkingDirectory "C:\Program Files (x86)\Microsoft Office\Office16" -FilePath .\POWERPNT.EXE -ArgumentList "/S `"blank.ppsx`"" 
Start-Sleep -Milliseconds 2000
Switch-Desktop -Desktop 0