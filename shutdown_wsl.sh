#!/bin/bash
set -e
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
echo "${TAB}running $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# get source directory
source_dir=$(dirname $src_name)
cd $source_dir
echo
hist_file=~/.bash_history
if [ -f $hist_file ]; then
     echo "#$(date +'%s') SHUTDN $(date +'%a %b %d %Y %R:%S %Z') from $(hostname -s)" >> $hist_file
fi
echo -n "connecting to powershell... "
powershell.exe Write-Output "done"
echo
powershell.exe wsl -l -v | sed 's/^/   /'
echo -e "\nshutting down wsl.exe...\n"
powershell.exe wsl --shutdown
