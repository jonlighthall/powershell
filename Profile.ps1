# The following command may need to be run to enable use of a profile
#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force #-Verbose

# check if running from command line
if ((Get-CimInstance win32_process -Filter "ProcessID=$PID" | Where-Object { $_.processname -eq "pwsh.exe" -or "powershell.exe"}) | Select-Object commandline) {
    # running from command line
    Write-Output "CLI"
}
else {
    # running as script
    Write-Output "script"
}

# Test each Arg for match of abbreviated '-NonInteractive' command.
$NonInteractive = [Environment]::GetCommandLineArgs() | Where-Object { $_ -like '-NonI*' }
if ([Environment]::UserInteractive -and -not $NonInteractive) {
    # We are in an interactive shell.
    $bInt = $true;

    # print source name at start
    $src_path = Get-Location
    $src_name = $MyInvocation.MyCommand.Name
    Write-Host "Running " -NoNewline
    Write-Host "$src_path\$src_name" -NoNewline -ForegroundColor Yellow
    Write-Host " (in an interactive shell)..."
}
else {
    # We are not in an interactive shell.
    Write-Debug "Not running in an interactive shell"
    $bInt = $false;
}

if ($bInt -eq $true) {
    write-host "Setting up environment..."
}

$TAB = "   "

# Add the module path to PSModulePath
$modulePath = "${HOME}\Documents\WindowsPowerShell\Modules"
if ($env:PSModulePath -like "*$modulePath*" -and $bInt -eq $true) {
    Write-Output "$TAB$modulePath is in PSModulePath"
}
else {
    if ($bInt -eq $true) {
        Write-Output "${TAB}$modulePath is not in PSModulePath"
        write-host "${TAB}${TAB}prepending $modulePath to PSModulePath..."
    }
    $env:PSModulePath = "$modulePath;" + $env:PSModulePath
}

# get the script path
$repo_dir = Get-Item $MyInvocation.MyCommand.Path
write-host "${TAB}$repo_dir invocation path"
if ($repo_dir.LinkType -eq "SymbolicLink") {
    $repo_dir = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty Target
    write-host "${TAB}$repo_dir link target"
}

$scriptPath = Split-Path -Parent $repo_dir
write-host "${TAB}$scriptPath directory"

# Add the script path to PATH
if ($env:PATH -like "*$scriptPath*" -and $bInt -eq $true) {
    Write-Output "${TAB}$scriptPath is in PATH"
}
else {
    if ($bInt -eq $true) {
        Write-Output "${TAB}$scriptPath is not in PATH"
        write-host "${TAB}${TAB}prepending $scriptPath to PATH"
    }
    $env:PATH = $scriptPath + ";" + $env:PATH
}

Set-PSReadLineOption -HistorySavePath 'C:\Users\jlighthall\OneDrive - US Navy-flankspeed\Documents\home\ConsoleHost_history.txt'

if ($bInt -eq $true) {
    Write-Output "Weclome to $env:COMPUTERNAME"
}
function gitr {
    git remote -v
}

function x {
    exit
}
