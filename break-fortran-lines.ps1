<#
.SYNOPSIS
  Wrap Fortran 77 fixed-form lines to a maximum column with proper continuation.
  FIXED VERSION - Comments are never touched, only code lines exceeding MaxCol are wrapped.

.PARAMETER InputFile
  File to process in-place (unless -DryRun is specified).

.PARAMETER MaxCol
  Maximum column for fixed-form line (default 72).

.PARAMETER ContChar
  Continuation character to place in column 6 for wrapped lines (default '>').

.PARAMETER DryRun
  If set, prints the transformed content to stdout without modifying the file.
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

  # Empty or null lines are treated as comments (don't process)
  if ([string]::IsNullOrWhiteSpace($line)) { return $true }

  # Check first character for classic Fortran comment markers
  $firstChar = $line[0]
  if ($firstChar -eq 'c' -or $firstChar -eq 'C' -or $firstChar -eq '*' -or $firstChar -eq '!') {
    return $true
  }

  # Check for lines that start with spaces followed by !
  $trimmed = $line.TrimStart()
  if ($trimmed.StartsWith('!')) {
    return $true
  }

  return $false
}

function Get-LabelCols {
  param([string]$line)
  $padded = $line.PadRight(6)
  $label = $padded.Substring(0, 5) # cols 1-5
  $col6 = $padded.Substring(5, 1) # col 6
  $code = if ($padded.Length -gt 6) { $padded.Substring(6) } else { '' }
  return @($label, $col6, $code)
}

function Find-SafeBreakIndex {
  param(
    [string]$code,
    [int]$maxCodeCols
  )

  # If the code fits within the limit, don't break it
  if ($code.Length -le $maxCodeCols) {
    return -1
  }

  # Check for inline comments - if found, don't break the line
  $inSQ = $false; $inDQ = $false
  for ($i = 0; $i -lt $code.Length; $i++) {
    $ch = $code[$i]
    if (-not $inDQ -and $ch -eq "'") { $inSQ = -not $inSQ }
    elseif (-not $inSQ -and $ch -eq '"') { $inDQ = -not $inDQ }
    elseif (-not $inSQ -and -not $inDQ -and $ch -eq '!') {
      return -1  # Don't break lines with inline comments
    }
  }

  # Find the best break point before maxCodeCols
  $limit = [Math]::Min($code.Length, $maxCodeCols)
  $inSQ = $false; $inDQ = $false
  $lastGood = -1

  for ($i = 0; $i -lt $limit; $i++) {
    $ch = $code[$i]
    if (-not $inDQ -and $ch -eq "'") { $inSQ = -not $inSQ }
    elseif (-not $inSQ -and $ch -eq '"') { $inDQ = -not $inDQ }
    if (-not $inSQ -and -not $inDQ) {
      if ($ch -match '[ ,+\-*/)\]]') {
        $lastGood = $i
      }
    }
  }

  if ($lastGood -ge 0) {
    return $lastGood + 1
  }

  return $limit
}

function Wrap-FixedFormLine {
  param([string]$line, [bool]$isContinuation)

  # NEVER touch comment lines
  if (Is-CommentLine $line) {
    return , $line
  }

  # Only process lines that actually exceed MaxCol
  if ($line.Length -le $MaxCol) {
    return , $line
  }

  $label5, $col6, $code = Get-LabelCols $line
  $output = @()
  $firstLabel5 = $label5
  $firstCol6 = if ($isContinuation) {
    if ([string]::IsNullOrWhiteSpace($col6)) { ' ' } else { $col6 }
  }
  else {
    $col6
  }

  # Smart continuation indentation
  $baseIndent = ([regex]::Match($code, '^[ ]*')).Value.Length
  $contSpacesCount = $baseIndent + 3
  if ($contSpacesCount -lt 0) { $contSpacesCount = 0 }
  $postContSpaces = ' ' * $contSpacesCount

  $currentIsFirst = $true
  $remaining = $code

  while ($true) {
    $prefix = if ($currentIsFirst) {
      $firstLabel5 + $firstCol6
    }
    else {
      '     ' + $ContChar + $postContSpaces
    }

    $prefixLen = $prefix.Length
    $maxThisLine = [Math]::Max(0, $MaxCol - $prefixLen)
    $breakAt = Find-SafeBreakIndex -code $remaining -maxCodeCols $maxThisLine

    if ($breakAt -lt 0) {
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

# Main processing
if (-not (Test-Path -LiteralPath $InputFile)) {
  throw "Input file not found: $InputFile"
}

$lines = Get-Content -LiteralPath $InputFile -ErrorAction Stop
$outLines = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
  if ($null -eq $line) {
    $outLines.Add('');
    continue
  }

  if ($line.Length -eq 0) {
    $outLines.Add($line);
    continue
  }

  $padded = $line.PadRight(6)
  $isCont = ($padded[5] -ne ' ')
  $wrapped = Wrap-FixedFormLine -line $line -isContinuation:$isCont

  foreach ($w in $wrapped) {
    $outLines.Add($w)
  }
}

$result = $outLines -join "`r`n"

if ($DryRun) {
  Write-Output $result
}
else {
  $tmp = [System.IO.Path]::GetTempFileName()
  try {
    # Write to temp file with error checking
    $result | Set-Content -LiteralPath $tmp -NoNewline -Encoding utf8 -ErrorAction Stop

    # Validate temp file was written correctly
    $tmpSize = (Get-Item -LiteralPath $tmp).Length
    if ($tmpSize -eq 0) {
      throw "Failed to write content to temporary file"
    }

    # Atomic move operation
    Move-Item -Force -LiteralPath $tmp -Destination $InputFile -ErrorAction Stop

    # Validate final file
    $finalSize = (Get-Item -LiteralPath $InputFile).Length
    if ($finalSize -eq 0) {
      throw "Final file is empty after move operation"
    }
  }
  catch {
    Write-Error "File write operation failed: $_"
    throw
  }
  finally {
    if (Test-Path -LiteralPath $tmp) {
      Remove-Item -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
  }
}