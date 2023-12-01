#!/bin/bash
set -e
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo "${TAB}${RUN_TYPE} $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# get source directory
source_dir=$(dirname $src_name)
cd $source_dir
echo
hist_file=${HOME}/.bash_history
if [ -f $hist_file ]; then
    echo "#$(date +'%s') SHUTDN $(date +'%a %b %d %Y %R:%S %Z') from $(hostname -s)" >>$hist_file
fi
echo -n "connecting to powershell... "
powershell.exe Write-Output "done"
echo

# Check if the restart_wsl.ps1 script exists in the current directory
if [ -f "restart_wsl.ps1" ]; then
    # Start PowerShell in a new terminal window and run the script
    powershell.exe -NoExit -Command "Start-Process powershell.exe -ArgumentList '-NoExit','-Command','.\restart_wsl.ps1'"
else
    echo "restart_wsl.ps1 script not found in the current directory."
fi
