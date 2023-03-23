cd /mnt/c/Users/jlighthall/Documents/powershell
powershell.exe -File ./blank.ps1
trap "echo ' $(sec2elap $SECONDS)'" EXIT
