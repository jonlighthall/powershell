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

echo "Starting wsl-vpnkit..."
echo "This window must remain open for WSL network connectivity."
echo

# Run wsl-vpnkit and capture output to detect when it's ready
wsl.exe -d wsl-vpnkit --cd /app wsl-vpnkit 2>&1 | while IFS= read -r line; do
    echo "$line"
    
    # Detect when all checks are complete
    if [[ "$line" == *"wget success for https://example.com"* ]]; then
        echo
        echo "✓ wsl-vpnkit is running and network connectivity established!"
        echo "  Keep this window open. Close it to stop wsl-vpnkit."
        echo
    fi
done
