param(
   [Parameter(Mandatory = $true)]
   [string]$InputFile,
   [int]$MaxCol = 72,
   [char]$ContChar = '>'
)

# Normalize existing continuation lines to smart indentation and desired continuation char
# Fixed-form rules:
# - Columns 1-5: label or blanks
# - Column 6: non-blank indicates continuation; we enforce ContChar there
# - Columns 7-72: statement text; continuation lines should have baseIndent + 3 spaces before code

function Get-BaseIndent {
   param([string]$line)
   # Determine base indent from the first non-continuation line's code starting at col 7
   if ($line.Length -lt 7) { return 0 }
   $code = $line.Substring([Math]::Min(6, $line.Length)) # zero-based index 6 is column 7
   # Count leading spaces in code section
   $i = 0
   while ($i -lt $code.Length -and $code[$i] -eq ' ') { $i++ }
   return $i
}

function Test-IsCommentLine {
   param([string]$line)
   if ([string]::IsNullOrEmpty($line)) { return $false }
   # Comment if col 1 is C/c/* or if line starts with ! after optional spaces
   if ($line.Length -ge 1) {
      $c0 = $line[0]
      if ($c0 -eq 'c' -or $c0 -eq 'C' -or $c0 -eq '*') { return $true }
   }
   $trim = $line.TrimStart()
   if ($trim.StartsWith('!')) { return $true }
   return $false
}

function Format-ContinuationLines {
   param([string[]]$lines)

   $out = New-Object System.Collections.Generic.List[string]
   $i = 0
   while ($i -lt $lines.Count) {
      $line = $lines[$i]
      if (Test-IsCommentLine -line $line) { $out.Add($line); $i++; continue }

      # Detect a continued statement: current line with blank col 6 and followed by continuation
      $isFirst = $line.Length -ge 6 -and ($line[5] -eq ' ' -or $line[5] -eq [char]0)
      $j = $i + 1
      $hasCont = $false
      if ($j -lt $lines.Count) {
         $next = $lines[$j]
         if (-not (Test-IsCommentLine -line $next)) {
            if ($next.Length -ge 6 -and $next[5] -ne ' ') { $hasCont = $true }
         }
      }
      if ($isFirst -and $hasCont) {
         # Determine base indent from first line's code section
         $baseIndent = Get-BaseIndent -line $line
         # Emit first line unchanged
         $out.Add($line)
         # Normalize all subsequent continuation lines until the chain ends
         while ($j -lt $lines.Count) {
            $cl = $lines[$j]
            if (Test-IsCommentLine -line $cl) { break }
            if (-not ($cl.Length -ge 6 -and $cl[5] -ne ' ')) { break }
            # Columns 1-5 preserved; enforce ContChar at col 6
            $prefix = if ($cl.Length -ge 5) { $cl.Substring(0, 5) } else { $cl.PadRight(5) }
            # Extract code area (col 7 onward)
            $code = if ($cl.Length -gt 6) { $cl.Substring(6) } else { '' }
            # Trim all leading spaces then add exactly desired spaces
            $desired = [Math]::Max(0, $baseIndent + 3)
            $newCode = (' ' * $desired) + $code.TrimStart()
            $rebuilt = $prefix + $ContChar + $newCode
            $out.Add($rebuilt)
            $j++
         }
         $i = $j
         continue
      }
      else {
         # Single continuation without detected start (e.g., file starts mid-block)
         if ($line.Length -ge 6 -and $line[5] -ne ' ') {
            # Derive base indent from nearest previous non-continuation line
            $k = $out.Count - 1
            $baseIndent = 0
            while ($k -ge 0) {
               $prev = $out[$k]
               if (!(Test-IsCommentLine -line $prev) -and $prev.Length -ge 6 -and ($prev[5] -eq ' ' -or $prev[5] -eq [char]0)) { $baseIndent = Get-BaseIndent -line $prev; break }
               $k--
            }
            $prefix = if ($line.Length -ge 5) { $line.Substring(0, 5) } else { $line.PadRight(5) }
            $code = if ($line.Length -gt 6) { $line.Substring(6) } else { '' }
            $desired = [Math]::Max(0, $baseIndent + 3)
            $newCode = (' ' * $desired) + $code.TrimStart()
            $rebuilt = $prefix + $ContChar + $newCode
            $out.Add($rebuilt)
         }
         else {
            $out.Add($line)
         }
         $i++
      }
   }
   return , $out.ToArray()
}

# Read file as UTF-8 text (use cmdlet encoding name to satisfy Windows PowerShell 5)
$original = Get-Content -LiteralPath $InputFile -Raw -Encoding utf8
# Fallback for environments where -Encoding utf8 may not be honored
if ($null -eq $original) {
   $original = [IO.File]::ReadAllText($InputFile, [System.Text.UTF8Encoding]::new($false))
}

# Split on CRLF or LF using regex (PowerShell uses .NET regex for -split)
$lines = $original -split "\r?\n"

$normalized = Format-ContinuationLines -lines $lines

# Write to a temp file first, then atomically replace the original
$tmpPath = "$InputFile.tmp"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($tmpPath, ($normalized -join [Environment]::NewLine), $utf8NoBom)
Move-Item -LiteralPath $tmpPath -Destination $InputFile -Force
