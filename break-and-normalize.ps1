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
   # Get initial file stats for validation
   $originalSize = (Get-Item -LiteralPath $InputFile).Length
   $originalLines = (Get-Content -LiteralPath $InputFile).Count

   # Run the global breaker first
   Write-Verbose "Running line breaker..."
   try {
      & $BreakerPath -InputFile $InputFile -MaxCol $MaxCol
   }
   catch {
      throw "Line breaker failed: $_"
   }

   # Then run the local normalizer
   Write-Verbose "Running continuation normalizer..."
   $normalizer = Join-Path -Path $PSScriptRoot -ChildPath 'normalize-fortran-continuations.ps1'
   try {
      & $normalizer -InputFile $InputFile -MaxCol $MaxCol
   }
   catch {
      throw "Normalizer failed: $_"
   }

   # Enhanced validation checks
   $newSize = (Get-Item -LiteralPath $InputFile).Length
   $newLines = (Get-Content -LiteralPath $InputFile).Count

   if ($newSize -le 0) {
      throw "Post-processing produced an empty file"
   }

   if ($newLines -lt ($originalLines * 0.8)) {
      throw "Post-processing lost too many lines (original: $originalLines, new: $newLines)"
   }

   if ($newSize -lt ($originalSize * 0.5)) {
      throw "Post-processing reduced file size too much (original: $originalSize bytes, new: $newSize bytes)"
   }

   # Success! Clean up the backup file
   Write-Verbose "Processing completed successfully. Cleaning up backup: $backup"
   Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
   Write-Host "✅ Fortran formatting completed successfully (processed $newLines lines)"
}
catch {
   Write-Error "❌ Error during processing: $_"
   # Restore from backup on error
   Write-Host "🔄 Restoring from backup: $backup"
   Copy-Item -LiteralPath $backup -Destination $InputFile -Force
   throw
}
