# Aug 2021 JCL

# this is a PowerShell script

# Must first run the following command before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# Must run in elevated prompt to make link


# set execution preferences
$ErrorActionPreference = "Stop"

# set tab
$TAB = "   "

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running " -NoNewline
Write-Host "$src_path\$src_name" -NoNewline -ForegroundColor Yellow
Write-Host "..."

## Copy and link PowerShell history from OneDrive

# define target (source)
# specify the path to the shared history (cloud) file in OneDrive
$target = "$env:OneDrive\Documents\home\ConsoleHost_history.txt"

# define link (destination)
# specify the path to the (local) Console Host history file
$link = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"

# check if local file exists
Write-Host "test local history..."
$do_append = $false
if (Test-Path -Path $link) {
    Write-Host "${TAB}$link found"
    # if the local file (link) exists, append the cloud (target) history to it
    $do_append = $true

    # check if the local file is a link
    Write-Host "${TAB}$link is... " -NoNewline
    $do_link = $false
    if ($link.LinkType -eq "SymbolicLink") {
        Write-Host "a link "
        Write-Host "${TAB}and points to... " -NoNewline
        $linkTarget = (Get-Item -Path $link).Target
        if ($linkTarget -eq $target) {
            Write-Host "$target"
            # if the local file (link) already points to the cloud (target) file, do not append,
            # do not link
            $do_append = $false
        }
        else {
            Write-Host "something else"
            write-host "$linkTarget" -ForegroundColor Red
            $do_link = $true
        }
    }
    else {
        Write-Host " not a link"
        $do_link = $true
    }
}
else {
    Write-Host "${TAB}$link not found"
    # check if the parent directory of $link exists
    $link_parent = Split-Path -Parent $link
    if (-not (Test-Path -Path $link_parent)) {
        Write-Host "${TAB}Parent directory does not exist: $link_parent"
        exit 1
    }
    else {
        Write-Host "${TAB}Parent directory exists: $link_parent"
        $do_link = $true
    }
}

# check if the target (cloud) file exists
Write-Host "test cloud history..."
if (Test-Path -Path $target) {
    Write-Host "${TAB}$target found"
    Write-Host "proceeding..."
}
else {
    Write-Host "${TAB}$target not found" -ForegroundColor Red
    Write-Host "${TAB}no history to link to`nexiting"
    exit 1
}

if ($do_link) {
    if ($do_append) {
        Write-Host "${TAB}proceeding with append, delete, and link..."
        Write-Host "${TAB}${TAB}appending local copy with cloud copy..."
        Add-Content -Path $target -Value $link

        Write-Host "${TAB}${TAB}renaming local copy"
        $dir = [io.path]::GetDirectoryName($link)
        $fname = [io.path]::GetFileNameWithoutExtension($link)
        $ext = [io.path]::GetExtension($link)
        Move-Item -v $link $dir\${fname}_$(get-date -f yyyy-MM-dd-hhmm)$ext
    }
    else {
        Write-Host "${TAB}no appending to do"
        Write-Host "${TAB}proceeding with link..."
    }
    Write-Host "${TAB}${TAB}creating symbolic link"
    cmd.exe /c mklink /J $link $target
}
else {
    Write-Host "${TAB}no linking to do"
}
write-host "done linking history"

Write-Host "List of profiles:"
$PROFILE | Format-List -Force

Write-Host "Current profile: ......... $profile"
write-host "Current user current host: " -noNewline
$cuch_profile = $PROFILE.CurrentUserCurrentHost
$cuch_profile

Write-Host "Current profile... " -NoNewline
if (Test-Path -Path $PROFILE.CurrentUserCurrentHost) {
    Write-Host "exists"

    Write-Host "${TAB}${TAB}renaming local copy"
    $dir = [io.path]::GetDirectoryName($cuch_profile)
    $fname = [io.path]::GetFileNameWithoutExtension($cuch_profile)
    $ext = [io.path]::GetExtension($cuch_profile)
    Move-Item -v $cuch_profile $dir\${fname}_$(get-date -f yyyy-MM-dd-hhmm)$ext
}
else {
    Write-Host "does not exist"
}

$myProfile = Join-Path -Path $src_path -ChildPath "Profile.ps1"

if (Test-Path -Path $myProfile) {
    Write-Host "${TAB}${TAB}linking profile..."

    Start-Process powershell.exe -Verb RunAs -ArgumentList "New-Item -Verbose -ItemType SymbolicLink -Path $cuch_profile -Target $myProfile"
}
else {
    Write-Host "${TAB}${TAB}profile not found" -ForegroundColor Red
    Write-Host "${TAB}${TAB}no profile to link to`nexiting"
    exit 1
}

write-host "done linking profile"

write-host "done"
