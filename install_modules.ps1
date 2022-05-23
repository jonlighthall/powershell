# The following commands must be run before running blank.ps1
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module PowerShellGet -AllowClobber -Force -Scope CurrentUser
Install-Module -Name VirtualDesktop -Scope CurrentUser -Force