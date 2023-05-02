#!/bin/bash
set -e
# print source name at start
echo -n "source: $BASH_SOURCE"
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
powershell.exe wsl -l -v | sed 's/^/   /'
echo -e "\nshutting down wsl.exe...\n"
#powershell.exe -File ./shutdown_wsl.ps1 &
powershell.exe wsl --shutdown
