#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Verbose
Write-Output "Weclome to $env:COMPUTERNAME"
$env:PSModulePath = $env:PSModulePath + ";${HOME}\Documents\WindowsPowerShell\Modules"