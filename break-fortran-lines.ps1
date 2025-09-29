<#!
.SYNOPSIS
  Wrap Fortran 77 fixed-form lines to a maximum column with proper continuation.

.DESCRIPTION
  - Preserves labels in columns 1-5 on the first physical line only.
  - Sets column 6 to a continuation character on wrapped lines (default '&').
  - Leaves comment lines (C/c/* in col 1, or lines whose first non-space is '!') untouched.
  - Avoids breaking inside quoted string literals (single or double quotes) when choosing a split point.
  - Prefers to break on commas, spaces, or common operators before the column limit.
  - Processes existing continuation lines as well (further wraps if they still exceed limit).

.PARAMETER InputFile
  File to process in-place (unless -DryRun is specified).

.PARAMETER MaxCol
  Maximum column for fixed-form line (default 72).

.PARAMETER ContChar
  Continuation character to place in column 6 for wrapped lines (default '&').

.PARAMETER DryRun
  If set, prints the transformed content to stdout without modifying the file.

.NOTES
  Fixed-form columns: 1-5 label, 6 continuation, 7-72 statement text.
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$InputFile,
  [int]$MaxCol = 72,
  [char]$ContChar = '>',
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Is-CommentLine {
  param([string]$line)
  if (-not $line) { return $true }
  # Treat preprocessor or classic comment markers in col 1 as non-wrappable
  if ($line.Length -ge 1 -and ($line[0] -eq '#' -or $line[0] -eq '!' -or $line[0] -eq 'c' -or $line[0] -eq 'C' -or $line[0] -eq '*')) { return $true }
  # For lines starting with spaces, treat '!' as inline comment marker
  $trim = $line.TrimStart()
  if ($trim.StartsWith('!')) { return $true }
  return $false
}

function Get-LabelCols {
  param([string]$line)
  # Ensure at least 6 columns
  $padded = $line.PadRight(6)
  $label = $padded.Substring(0, 5) # cols 1-5
  $col6 = $padded.Substring(5, 1) # col 6
  $code = if ($padded.Length -gt 6) { $padded.Substring(6) } else { '' }
  return @($label, $col6, $code)
}

function Find-SafeBreakIndex {
  param(
    [string]$code,      # code text starting at column 7 (index 0 of this string)
    [int]$maxCodeCols   # max columns available for this physical line's code part
  )
  if ($code.Length -le $maxCodeCols) { return -1 }

  # First, check if there's an inline comment (!) - if so, don't break the line at all
  $inSQ = $false; $inDQ = $false
  for ($i = 0; $i -lt $code.Length; $i++) {
    $ch = $code[$i]
    if (-not $inDQ -and $ch -eq "'") { $inSQ = -not $inSQ }
    elseif (-not $inSQ -and $ch -eq '"') { $inDQ = -not $inDQ }
    elseif (-not $inSQ -and -not $inDQ -and $ch -eq '!') {
      # Found inline comment - don't break this line
      return -1
    }
  }

  # No inline comment found, proceed with normal breaking logic
  $limit = [Math]::Min($code.Length, $maxCodeCols)
  $inSQ = $false; $inDQ = $false
  $lastGood = -1
  for ($i = 0; $i -lt $limit; $i++) {
    $ch = $code[$i]
    if (-not $inDQ -and $ch -eq "'") { $inSQ = -not $inSQ }
    elseif (-not $inSQ -and $ch -eq '"') { $inDQ = -not $inDQ }
    if (-not $inSQ -and -not $inDQ) {
      if ($ch -match '[ ,+\-*/)\]]') { $lastGood = $i }
    }
  }
  if ($lastGood -ge 0) { return $lastGood + 1 } # break AFTER the good char
  # fallback: hard break near limit to avoid overflow
  return $limit
}

function Wrap-FixedFormLine {
  param([string]$line, [bool]$isContinuation)
  # Leave comments unchanged
  if (Is-CommentLine $line) { return , $line }

  $label5, $col6, $code = Get-LabelCols $line

  $output = @()
  # For the first physical line: keep existing label (cols 1-5) and col6 as-is.
  $firstLabel5 = $label5
  $firstCol6 = if ($isContinuation) { if ([string]::IsNullOrWhiteSpace($col6)) { ' ' } else { $col6 } } else { $col6 }

  # Determine smart continuation indentation based on leading spaces
  # in the code part of the original (current) line. Continuation lines
  # will start at baseIndent + 3 relative to column 7.
  $baseIndent = ([regex]::Match($code, '^[ ]*')).Value.Length
  $contSpacesCount = $baseIndent + 3
  if ($contSpacesCount -lt 0) { $contSpacesCount = 0 }
  $postContSpaces = ' ' * $contSpacesCount

  $currentIsFirst = $true
  $remaining = $code
  while ($true) {
    # For generated continuation lines, put the continuation char in
    # column 6 and add smart spaces after it (base indent + 3)
    $prefix = if ($currentIsFirst) { $firstLabel5 + $firstCol6 } else { '     ' + $ContChar + $postContSpaces }
    $prefixLen = $prefix.Length
    $maxThisLine = [Math]::Max(0, $MaxCol - $prefixLen)
    $breakAt = Find-SafeBreakIndex -code $remaining -maxCodeCols $maxThisLine
    if ($breakAt -lt 0) {
      # fits; emit and stop
      $output += ($prefix + $remaining)
      break
    }
    else {
      $firstPart = $remaining.Substring(0, $breakAt).TrimEnd()
      $output += ($prefix + $firstPart)
      $remaining = $remaining.Substring($breakAt).TrimStart()
      $currentIsFirst = $false
    }
  }
  return $output
}

if (-not (Test-Path -LiteralPath $InputFile)) {
  throw "Input file not found: $InputFile"
}

$in = Get-Content -LiteralPath $InputFile -Raw -ErrorAction Stop
# Split preserving empty trailing line
$lines = $in -split "\r?\n", -1

$outLines = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
  if ($null -eq $line) { $outLines.Add(''); continue }
  if ($line.Length -eq 0) { $outLines.Add($line); continue }
  $padded = $line.PadRight(6)
  $isCont = ($padded[5] -ne ' ')
  $wrapped = Wrap-FixedFormLine -line $line -isContinuation:$isCont
  foreach ($w in $wrapped) { $outLines.Add($w) }
}

if ($DryRun) {
  $outLines -join "`r`n" | Write-Output
}
else {
  $tmp = [System.IO.Path]::GetTempFileName()
  try {
    $outLines -join "`r`n" | Set-Content -LiteralPath $tmp -NoNewline -Encoding utf8
    Move-Item -Force -LiteralPath $tmp -Destination $InputFile
  }
  finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -Force -LiteralPath $tmp -ErrorAction SilentlyContinue }
  }
}
