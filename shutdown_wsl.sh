cd /mnt/c/Users/jlighthall/Documents/powershell
powershell.exe -File ./shutdown_wsl.ps1
trap "echo ' $(sec2elap $SECONDS)'" EXIT