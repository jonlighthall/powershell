# Mar 2023 JCL

# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Calculate elapsed time
function Get-ElapsedTime {
    param (
        [Parameter(Mandatory = $true)]
        [datetime]$StartTime
    )
    $elapsedTime = $(get-date) - $StartTime
    return $elapsedTime
}

# Format elapsed time
function Format-ElapsedTime($elapsedTime) {
    if ($elapsedTime.TotalSeconds -lt 1) {
        return "{0,5:n1} ms" -f $($elapsedTime.TotalMilliseconds)
    }
    elseif ($elapsedTime.TotalSeconds -lt 60) {
        return "{0,4:n1} s" -f $($elapsedTime.TotalSeconds)
    }
    elseif ($elapsedTime.TotalMinutes -lt 60) {
        return "{0,4:n1} min" -f $($elapsedTime.TotalMinutes)
    }
    else {
        return "{0:n1} hr" -f $($elapsedTime.TotalHours)
    }
}

# Write elapsed time
function Write-ElapsedTime($prefixText) {
    Write-Host "$prefixText elapsed time = $(Format-ElapsedTime $(Get-ElapsedTime $StartTime))"
}

# Indent text (move cursor)
function Set-TextIndent($indent) {
    $cur_pos = $host.UI.RawUI.CursorPosition
    $cur_pos.X = 16 + $indent
    $host.UI.RawUI.CursorPosition = $cur_pos
}

# Anti-indent text (move cursor back) to align with following text with indent
function Write-TextIndentPrefix($prefixText) {
    Set-TextIndent -$($prefixText.Length)
    write-host -NoNewline "$prefixText"
}

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

# get window title
$currentWindowTitle = $host.ui.RawUI.WindowTitle
Write-Host "   old window title: $currentWindowTitle"

#set a unique window title and get matching PID
$src_win = "$src_name $(Get-Date -Format HH:mm)"
$host.ui.RawUI.WindowTitle = "$src_win"
Write-Host "   new window title: $src_win"
$src_proc = Get-Process | Where-Object { $_.mainWindowTitle -like ${src_win} }
$src_pid = $(($src_proc).Id)
Write-Host "   PID = $src_pid"

# define time
$StartTime = $(get-date)

# -------------------------------------
# BLINK SETTINGS
# -------------------------------------

# define maximum wait time between loops in minutes
$global:loop_wait_min = 4 / 1000

# define time between key blinks in milliseconds
$global:blink_wait_ms = 32

# define number of blinks per loop
$global:blinks_per_loop = 2

# define keys to blink
$global:keys = @("{CAPSLOCK}", "{SCROLLLOCK}", "{NUMLOCK}")

# define maximum number of keys to blink per loop
$global:key_max = 1

# -------------------------------------
# TEXT SETTINGS
# -------------------------------------

# define text to type on each loop
$global:txt = "All work and no play makes Jack a dull boy."

# define whether to type text on each loop
$global:do_text = $true
# -------------------------------------

# loop settings
$loop_wait_s = $loop_wait_min * 60
$loop_wait_ms = $loop_wait_s * 1000
$loops_per_hour = $([int](60 / $loop_wait_min))

# clicker settings
$nkeys = $keys.Length
$key_lim = [Math]::Min($nkeys, $key_max)

# print settings
$line_lim = 10
if ($loops_per_hour -gt $line_lim) {
    $ndots = $line_lim
}
else {
    $ndots = $loops_per_hour
}
Write-Host "Press Ctrl-C to exit."
# set wait message
$msg = "WAIT"
Write-Host "Do not exit while $msg is displayed."
$counter = 0
$WShell = New-Object -ComObject Wscript.Shell

try {
    while ($true) {
        if ($src_pid -gt 0) {
            $null = (New-Object -ComObject WScript.Shell).AppActivate($src_pid)
            $pid_ok = $true
        }
        else {
            $pid_ok = $false
        }
        if ($counter -gt 0) {
            # print wait message
            Write-Host -NoNewline -ForegroundColor Red "$($PSStyle.bold)$msg$($PSStyle.BoldOff)"

            # type text message
            if ($do_text -and $pid_ok) {
                $WShell.sendkeys("$txt")
            }

            # loop over blinks_per_loop, twice
            # for each blink loop
            #   * loop over keys and send each key
            #   * wait for blink interval
            #   * loop over kesy again and send each key (resetting status)
            for ($j = 0; $j -lt ($blinks_per_loop * 2); $j++) {
                # loop over keys
                for ($i = 0; $i -lt $key_lim; $i++) {
                    $WShell.sendkeys($($keys[$i]))
                }
                # wait
                Start-Sleep -Milliseconds $blink_wait_ms
            }

            # clear text message
            if ($do_text -and $pid_ok) {
                #Start-Sleep -Milliseconds 500
                # send the backspace key a number of times equal to the length of the text message
                $WShell.sendkeys($("{BS}" * $txt.Length))
            }
            # clear wait message
            $cur_pos = $host.UI.RawUI.CursorPosition;
            $cur_pos.X -= $msg.Length;
            $host.UI.RawUI.CursorPosition = $cur_pos
            Write-Host -NoNewline $(" " * $msg.Length)
            # reset cursor position
            $cur_pos = $host.UI.RawUI.CursorPosition
            $cur_pos.X -= $msg.Length;
            $host.UI.RawUI.CursorPosition = $cur_pos
        }

        # after ndots number of loops, print the elapsed time
        if (($counter % $ndots) -eq 0) {
            if ($counter -gt 0) {
                # define elapsed time
                $elapsedTime = $(get-date) - $StartTime

                # print elapsed time
                Write-Host " elapsed time = $(Format-ElapsedTime $elapsedTime)"

                # exit after 10 hours
                if ($elapsedTime.TotalHours -ge 10) {
                    Write-TextIndentPrefix "PS:"
                    write-host -ForegroundColor Red " elapsed time exceeds 10 hr"
                    exit
                }
            }
            Write-Host -NoNewline "$(Get-Date -Format HH:mm) "
        }

        # print dot and increment counter
        Write-Host -NoNewline "."
        $counter++

        # wait a randomized amount of time before next loop
        $this_wait = Get-Random -Minimum 0 -Maximum $loop_wait_ms
        $this_wait = $([int] $this_wait)
        Start-Sleep -Milliseconds $this_wait
    }
}
# beep and reset window title on exit
finally {
    Write-TextIndentPrefix "EXIT:"
    Write-ElapsedTime
    Write-Host -NoNewLine "`a"
    $host.ui.RawUI.WindowTitle = $currentWindowTitle
}
