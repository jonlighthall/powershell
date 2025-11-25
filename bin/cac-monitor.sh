#!/bin/bash
# Wrapper to run CAC monitor in Windows PowerShell from WSL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/cac-monitor.ps1"

# Convert WSL path to Windows path
WIN_PATH=$(wslpath -w "$SCRIPT_PATH")

echo "Starting CAC monitor in Windows PowerShell..."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH"
