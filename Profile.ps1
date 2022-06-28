# The following command may need to be run enable use of a profile
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Verbose
Write-Output "Weclome to $env:COMPUTERNAME"
$env:PSModulePath = $env:PSModulePath + ";${HOME}\Documents\WindowsPowerShell\Modules"