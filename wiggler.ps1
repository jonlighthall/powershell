# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# print source name at start
$src_path = Get-Location
$src_name = $MyInvocation.MyCommand.Name
Write-Host "running $src_path\$src_name..."

#get PID
$src_win = "$src_name $(Get-Date -Format HH:mm)"
$host.ui.RawUI.WindowTitle = "$src_win"
Write-Host "   window title should be $src_win"
$src_proc = Get-Process | Where-Object { $_.mainWindowTitle -like ${src_win} }
$src_pid = $(($src_proc).Id)
Write-Host "   PID = $src_pid"

# define time
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

# loop settings
$loop_wait_min = 4
$loop_wait_s = $loop_wait_min * 60
$loop_wait_ms = $loop_wait_s * 1000
$loops_per_hour = $([int](60 / $loop_wait_min))

# wiggler settings
Add-Type -AssemblyName System.Windows.Forms

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

try {
    while ($true) {
        if ($src_pid -gt 0) {
            $null = (New-Object -ComObject WScript.Shell).AppActivate($src_pid)
        }

        if ($counter -gt 0) {
            # print wait message
            Write-Host -NoNewline -ForegroundColor Red "$($PSStyle.bold)$msg$($PSStyle.BoldOff)"


            # move mouse
            $originalPosition = [System.Windows.Forms.Cursor]::Position
            $newX = $originalPosition.X + (Get-Random -Minimum -5 -Maximum 5)
            $newY = $originalPosition.Y + (Get-Random -Minimum -5 -Maximum 5)
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)

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
                # format elapsed time
                if ($elapsedTime.TotalSeconds -lt 1) {
                    Write-Host " elapsed time = $("{0,5:n1}" -f $($elapsedTime.TotalMilliseconds)) ms"
                }
                elseif ($elapsedTime.TotalSeconds -lt 60) {
                    Write-Host " elapsed time = $("{0,4:n1}" -f $($elapsedTime.TotalSeconds)) s"
                }
                elseif ($elapsedTime.TotalMinutes -lt 60) {
                    Write-Host " elapsed time = $("{0,4:n1}" -f $($elapsedTime.TotalMinutes)) min"
                }
                else {
                    Write-Host " elapsed time = $("{0:n1}" -f $($elapsedTime.TotalHours)) hr"
                }

                # exit after 10 hours
                if ($elapsedTime.TotalHours -ge 10) {
                    $cur_pos = $host.UI.RawUI.CursorPosition
                    $cur_pos.X = 16 - 3
                    $host.UI.RawUI.CursorPosition = $cur_pos
                    Write-Host "PS: elapsed time exceeds 10 hr"
                    exit
                }
            }
            Write-Host -NoNewline "$(Get-Date -Format HH:mm) "
        }
        Write-Host -NoNewline "."
        $counter++
        $this_wait = Get-Random -Minimum 0 -Maximum $loop_wait_ms
        $this_wait = $([int] $this_wait)
        Start-Sleep -Milliseconds $this_wait
    }
}
# beep and reset window title on exit
finally {
    Write-Host -NoNewLine "`a"
    $host.ui.RawUI.WindowTitle = "Ubuntu"
}
