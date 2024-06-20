#!/bin/bash

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
powershell.exe -File ../clicker.ps1
trap "echo -e '\x1B[11G BASH: $(sec2elap $SECONDS)';clear -x" EXIT
