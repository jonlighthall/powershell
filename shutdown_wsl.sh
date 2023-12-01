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
powershell.exe 'Write-Output "done"; Write-Host "shutting down WSL..."'
powershell.exe -Command "wsl --shutdown"

# under Settings->Defaults->Advanced->Profile termination behavior, select Close
# only when process exists successfully, then running this script will allow the
# user to reset each terminal by pressing Enter
