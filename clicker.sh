#!/bin/bash

# set tab
TAB=${TAB:=''}

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
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
  echo -e "${TAB}${VALID}link${RESET} -> $src_name"
fi

# get source directory
source_dir=$(dirname "$src_name")
cd $source_dir
echo -n "connecting to powershell... "
powershell.exe Write-Output "done"
clear -x
powershell.exe -File ./scrlk.ps1
trap "echo -e '\x1B[11G BASH: $(sec2elap $SECONDS)';clear -x" EXIT
