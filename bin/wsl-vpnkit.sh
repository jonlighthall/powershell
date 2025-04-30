#!/bin/bash
#
# Run WSL VPN kit to provide network connectivity to the WSL 2 VM via the
#   existing Winodws nework connection.
#
# DOWNLOAD
#   https://github.com/sakai135/wsl-vpnkit/releases/latest
#
# INSTALL
#   PS> wsl --import wsl-vpnkit --version 2 $env:USERPROFILE\wsl-vpnkit wsl-vpnkit.tar.gz
#
# Apr 2025 JCL

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
