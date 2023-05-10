#!/bin/bash
set -e
# print source name at start
echo -n "${TAB}running $BASH_SOURCE"
src_name=$(readlink -f $BASH_SOURCE)
if [ $BASH_SOURCE = $src_name ]; then
    echo
else
    echo " -> $src_name"
fi
# get source directory
src_dir=$(dirname $src_name)
cd $src_dir
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
