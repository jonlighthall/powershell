#!/bin/bash
# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
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
  echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# get source directory
source_dir=$(dirname $src_name)
cd $source_dir
powershell.exe -File ./blank.ps1
trap "echo ' $(sec2elap $SECONDS)'" EXIT
