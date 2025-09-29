param(
   [Parameter(Mandatory = $true)]
   [string]$InputFile,
   [int]$MaxCol = 72,
   [string]$BreakerPath = 'C:/Users/jlighthall/Documents/home/ubuntu/repos/powershell/break-fortran-lines.ps1'
)

if (-not (Test-Path -LiteralPath $InputFile)) {
   throw "Input file not found: $InputFile"
}
if (-not (Test-Path -LiteralPath $BreakerPath)) {
   throw "Breaker script not found: $BreakerPath"
}

# Create a timestamped backup before any changes
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$InputFile.bak.$timestamp"
Copy-Item -LiteralPath $InputFile -Destination $backup -Force

try {
   # Run the global breaker first
   & $BreakerPath -InputFile $InputFile -MaxCol $MaxCol

   # Then run the local normalizer
   $normalizer = Join-Path -Path $PSScriptRoot -ChildPath 'normalize-fortran-continuations.ps1'
   & $normalizer -InputFile $InputFile -MaxCol $MaxCol

   # Basic sanity check: file should not be empty after processing
   $len = (Get-Item -LiteralPath $InputFile).Length
   if ($len -le 0) {
      throw "Post-processing produced an empty file; restored from backup $backup"
   }
}
catch {
   Write-Error $_
   # Restore from backup on error
   Copy-Item -LiteralPath $backup -Destination $InputFile -Force
   throw
}
