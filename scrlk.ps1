# The following command may need to be run before running this script
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# print source name at start
$scr_path = Get-Location
$scr_name = $MyInvocation.MyCommand.Name
Write-Host "running $scr_path\$scr_name..."

# define time
$StartTime = $(get-date)
$elapsedTime = $(get-date) - $StartTime

# loop settings
$loop_wait_min = 4
$loop_wait_s = $loop_wait_min*60
$loop_wait_ms = $loop_wait_s*1000
$loops_per_hour = $([int](60/$loop_wait_min))

# blink settings
$blink_wait_ms = 32
$blinks_per_loop = 2

# clicker settings
$keys=@("{CAPSLOCK}","{SCROLLLOCK}","{NUMLOCK}")
$nkeys=$keys.Length
$WShell = New-Object -ComObject Wscript.Shell

# print settings
$line_lim=10
if ($loops_per_hour -gt $line_lim) {
    $ndots=$line_lim
}
else {
    $ndots=$loops_per_hour
}
Write-Host "Press Ctrl-C to exit."
# set wait message
$msg="WAIT"
Write-Host "Do not exit when $msg is displayed."
$counter = 0
$txt="All work and no play makes Jack a dull boy."

while ($true) {
    if ($counter -gt 0) {        
        Write-Host -NoNewline -ForegroundColor Red "$($PSStyle.bold)$msg$($PSStyle.BoldOff)"                        
        $WShell.sendkeys("$txt")
        for ($j=0;$j -lt ($blinks_per_loop*2);$j++) {
            for ($i=0;$i -lt $nkeys;$i++) {                                
                $WShell.sendkeys($($keys[$i]))
            }            
            Start-Sleep -Milliseconds $blink_wait_ms
        }
        #Start-Sleep -Milliseconds 500
        $WShell.sendkeys($("{BS}" * $txt.Length))
        # clear wait message
        $cur_pos=$host.UI.RawUI.CursorPosition;
        $cur_pos.X-=$msg.Length;      
        $host.UI.RawUI.CursorPosition=$cur_pos                
        Write-Host -NoNewline $(" " * $msg.Length)
        # reset cursor position
        $cur_pos=$host.UI.RawUI.CursorPosition
        $cur_pos.X -=$msg.Length;
        $host.UI.RawUI.CursorPosition=$cur_pos                
    }
    
    if (($counter % $ndots) -eq 0) {
        if ($counter -gt 0) {	                                
            $elapsedTime = $(get-date) - $StartTime
            if ($elapsedTime.TotalSeconds -lt 1) {
                Write-Host " elapsed time = $("{0,5:n1}" -f $($elapsedTime.TotalMilliseconds)) ms"
            } elseif ($elapsedTime.TotalSeconds -lt 60) {
                Write-Host " elapsed time = $("{0,4:n1}" -f $($elapsedTime.TotalSeconds)) s"
            } elseif ($elapsedTime.TotalMinutes -lt 60) {
                Write-Host " elapsed time = $("{0,4:n1}" -f $($elapsedTime.TotalMinutes)) min"    
            } else {
                Write-Host " elapsed time = $("{0:n1}" -f $($elapsedTime.TotalHours)) hr"    
            }
            if  ($elapsedTime.TotalHours -ge 10) {               
                $cur_pos=$host.UI.RawUI.CursorPosition
                $cur_pos.X=16-3
                $host.UI.RawUI.CursorPosition=$cur_pos
                Write-Host "PS: elapsed time exceeds 10 hr"                        
                exit
            }                
        }
        Write-Host -NoNewline "$(Get-Date -Format HH:mm) "
    }
    Write-Host -NoNewline "."	
    $counter++    
    Start-Sleep -Milliseconds $loop_wait_ms
}