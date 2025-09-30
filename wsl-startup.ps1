# WSL Startup Script for VS Code Connectivity
# This script ensures WSL is running and ready for VS Code connections

Write-Host "Starting WSL and preparing for VS Code connections..." -ForegroundColor Green

# Start WSL with your default distribution
Write-Host "Starting WSL Ubuntu-18.04..." -ForegroundColor Yellow
try {
    wsl.exe --distribution Ubuntu-18.04 --exec echo "WSL Started Successfully"
    Write-Host "✓ WSL started successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start WSL: $_" -ForegroundColor Red
    exit 1
}

# Check WSL status
Write-Host "`nChecking WSL status..." -ForegroundColor Yellow
wsl.exe --list --verbose

# Clear VS Code server cache if it exists (helps with connection issues)
Write-Host "`nClearing VS Code server cache..." -ForegroundColor Yellow
wsl.exe --distribution Ubuntu-18.04 --exec bash -c 'rm -rf ~/.vscode-server/bin/.* 2>/dev/null || true'
Write-Host "✓ VS Code cache cleared" -ForegroundColor Green

# Test basic WSL connectivity
Write-Host "`nTesting WSL connectivity..." -ForegroundColor Yellow
$wslTest = wsl.exe --distribution Ubuntu-18.04 --exec bash -c 'echo Connection test successful'
if ($wslTest -match "Connection test successful") {
    Write-Host "✓ WSL is ready for VS Code connections" -ForegroundColor Green
} else {
    Write-Host "✗ WSL connectivity test failed" -ForegroundColor Red
}

Write-Host "`nWSL startup complete. You can now connect VS Code to WSL." -ForegroundColor Green