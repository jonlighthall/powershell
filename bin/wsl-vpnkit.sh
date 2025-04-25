#!/bin/bash
#
# Mar 2023 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
    rtab
    print_source
fi

# get source directory
source_dir=$(dirname "$src_name")
cd $source_dir
echo -n "connecting to powershell... "
powershell.exe Write-Output "done"
clear -x
powershell.exe wsl.exe -d wsl-vpnkit --cd /app wsl-vpnkit
