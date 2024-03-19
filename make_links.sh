#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

utils_dir="${HOME}/utils"
bash_utils_dir="${utils_dir}/bash"

# load formatting
fpretty="${bash_utils_dir}/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
    # reset tab
    rtab
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
fi
# print source name at start
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${RESET}..."
src_name=$(readlink -f "$BASH_SOURCE")
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${RESET} -> $src_name"
fi

# set target and link directories
src_dir_logi=$(dirname "$src_name")
proj_name=$(basename "$src_dir_logi")
target_dir="${utils_dir}/${proj_name}"
link_dir=$HOME/bin

# check directories
echo -n "target directory ${target_dir}... "
if [ -d "$target_dir" ]; then
    echo "exists"
else
    echo -e "${BAD}does not exist${RESET}"
    exit 1
fi

echo -n "link directory ${link_dir}... "
if [ -d "$link_dir" ]; then
    echo "exists"
else
    echo "does not exist"
    mkdir -pv "$link_dir"
fi

bar 38 "------ Start Linking Repo Files-------"

# list of files to be linked
ext=.sh
for my_link in blank clicker wsl_shutdown; do
    # define target (source)
    target=${target_dir}/${my_link}${ext}
    # define link (destination)
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
        # strip target subdirectory from link name
        my_link=$(basename "$my_link")
    fi
    link=${link_dir}/${my_link}
    echo "linking $target to $link..."

    do_link_exe "$target" "$link"
done
bar 38 "--------- Done Making Links ----------"
