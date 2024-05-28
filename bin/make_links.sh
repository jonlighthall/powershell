#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

utils_dir="${HOME}/utils"
config_dir="${HOME}/config"
bash_utils_dir="${utils_dir}/bash"

# load bash utilities
fpretty="${config_dir}/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
fi
print_source

# set target and link directories
src_dir_logi=$(dirname "$src_name")
echo "source dir: $src_dir_logi"
proj_name=$(basename "$src_dir_logi")
echo "proj dir: $proj_name"
if [[ "${proj_name}" == "bin" ]]; then

    proj_name=$(basename $(dirname "$src_dir_logi"))
    bin_dir=$proj_name/bin
    echo "bin dir: $bin_dir"
    echo "proj dir: $proj_name"
    target_dir="${utils_dir}/${bin_dir}"
else
    target_dir="${utils_dir}/${proj_name}"
fi
   

echo "target dir: $target_dir"
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

cbar "Start Linking Repo Files"

# list of files to be linked
ext=.sh
for my_link in blank clicker wiggler wsl_shutdown; do
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
cbar "Done Making Links"
