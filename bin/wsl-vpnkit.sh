#!/bin/bash
#
# Run WSL VPN kit to provide network connectivity to the WSL 2 VM via the
#   existing Windows network connection.
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

# If already running, exit quietly to avoid duplicate instance
if wsl.exe -d wsl-vpnkit --exec sh -c "pgrep -f '/app/wsl-vm' >/dev/null 2>&1"; then
    # If running in an interactive terminal, show a friendly note.
    if [ -t 1 ]; then
        echo "wsl-vpnkit is already running; not starting another instance."
    fi
    # Exit quietly to avoid window blink when launched via 'start'.
    exit 0
fi

echo "Starting wsl-vpnkit..."
echo "This window must remain open for WSL network connectivity."
echo

# Run wsl-vpnkit
wsl.exe -d wsl-vpnkit --cd /app wsl-vpnkit
