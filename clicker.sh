#!/bin/bash

# set tab
TAB=${TAB:=''}

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
powershell.exe -File ./scrlk.ps1
trap "echo -e '\x1B[11G BASH: $(sec2elap $SECONDS)'" EXIT