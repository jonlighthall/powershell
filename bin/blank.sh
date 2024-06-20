#!/bin/bash

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
    set_traps
fi

# print source name at start
if ! (return 0 2>/dev/null); then
    set -e
fi
print_source

# get source directory
source_dir=$(dirname "$src_name")
cd $source_dir
echo -n "connecting to powershell... "
powershell.exe -NonInteractive 'Write-Output "done"'
powershell.exe -File ../blank.ps1
