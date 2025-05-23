#!/bin/bash -u
#
# Mar 2023 JCL

# get starting time in nanoseconds
start_time=$(date +%s%N)

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# determine if script is being sourced or executed
if ! (return 0 2>/dev/null); then
    # exit on errors
    set -e
fi
print_source

# set target and link directories
src_dir_logi=$(dirname "$src_name")
echo "source dir: $src_dir_logi"
proj_name=$(basename "$src_dir_logi")
echo "proj dir: $proj_name"
utils_dir="${HOME}/utils"
if [[ "${proj_name}" == "bin" ]]; then
    proj_name=$(basename $(dirname "$src_dir_logi"))
    bin_dir=$proj_name/bin
    echo "bin dir: $bin_dir"
    echo "proj dir: $proj_name"
    target_dir="${utils_dir}/${bin_dir}"
else
    target_dir="${utils_dir}/${proj_name}"
fi
link_dir=$HOME/bin

# check directories
check_target "${target_dir}"
do_make_dir "$link_dir"

cbar "Start Linking Repo Files"
# list of files to be linked
ext=.sh
for my_link in blank clicker wiggler wsl-vpnkit wsl_shutdown; do
    # define target (source)
    target=${target_dir}/${my_link}${ext}
    # define link name (destination)
    sub_dir=$(dirname "$my_link")
    if [ ! $sub_dir = "." ]; then
        # strip target subdirectory from link name
        my_link=$(basename "$my_link")
    fi
    link=${link_dir}/${my_link}
    # create link
    do_link_exe "${target}" "${link}"
done
cbar "Done Linking Repo Files"
