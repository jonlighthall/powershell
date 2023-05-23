#!/bin/bash
# print source name at start
echo "${TAB}running $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! $BASH_SOURCE = $src_name ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi
# get source directory
src_dir=$(dirname $src_name)
cd $src_dir
powershell.exe -File ./scrlk.ps1
trap "echo ' $(sec2elap $SECONDS)'" EXIT
