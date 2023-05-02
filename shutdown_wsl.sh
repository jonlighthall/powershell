#!/bin/bash
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
powershell.exe -File ./shutdown_wsl.ps1

# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"

trap "echo ' $(sec2elap $SECONDS)'" EXIT
