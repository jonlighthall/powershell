# CAC Card Reader Monitor - Simple Detection Script
# Must run in Windows PowerShell to access Smart Card APIs

Write-Host "CAC Monitor - Starting..." -ForegroundColor Cyan

# --- Policy & Auditing Configuration ---
$EnableEventLog = $true
$EventLogName = 'Application'
$EventSource = 'CACMonitor'
$AllowForceKill = $false  # Only allow force-kill if explicitly enabled

function Write-CacEvent {
    param(
        [int]$Id,
        [string]$Message,
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Type = 'Information'
    )
    try {
        if ($EnableEventLog) {
            if (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
                # Creating a source requires admin; if not available, skip without failing
                try { New-EventLog -LogName $EventLogName -Source $EventSource -ErrorAction Stop } catch {}
            }
            Write-EventLog -LogName $EventLogName -Source $EventSource -EventId $Id -EntryType $Type -Message $Message -ErrorAction SilentlyContinue
        }
    }
    catch {}
}

# Define PC/SC (Smart Card) API and Idle Time Tracking
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class PCSC {
    [DllImport("winscard.dll")]
    public static extern int SCardEstablishContext(int dwScope, IntPtr pvReserved1, IntPtr pvReserved2, out IntPtr phContext);

    [DllImport("winscard.dll")]
    public static extern int SCardReleaseContext(IntPtr hContext);

    [DllImport("winscard.dll", CharSet = CharSet.Auto)]
    public static extern int SCardListReaders(IntPtr hContext, byte[] mszGroups, IntPtr mszReaders, ref int pcchReaders);

    [DllImport("winscard.dll", CharSet = CharSet.Auto)]
    public static extern int SCardConnect(IntPtr hContext, string szReader, int dwShareMode, int dwPreferredProtocols, out IntPtr phCard, out int pdwActiveProtocol);

    [DllImport("winscard.dll")]
    public static extern int SCardDisconnect(IntPtr hCard, int dwDisposition);

    [DllImport("winscard.dll", CharSet = CharSet.Auto)]
    public static extern int SCardStatus(IntPtr hCard, byte[] szReaderName, ref int pcchReaderLen, out int pdwState, out int pdwProtocol, byte[] pbAtr, ref int pcbAtrLen);

    public const int SCARD_SCOPE_USER = 0;
    public const int SCARD_SHARE_SHARED = 2;
    public const int SCARD_PROTOCOL_T0 = 1;
    public const int SCARD_PROTOCOL_T1 = 2;
    public const int SCARD_LEAVE_CARD = 0;
    public const int SCARD_STATE_PRESENT = 0x00000020;
    public const int SCARD_W_REMOVED_CARD = unchecked((int)0x80100069);
}

public struct LASTINPUTINFO {
    public uint cbSize;
    public uint dwTime;
}

public class IdleTime {
    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
}
"@
}
catch {
    Write-Host "Failed to load interop types: $($_.Exception.Message)" -ForegroundColor Red
    Write-CacEvent -Id 9001 -Message ("Interop Add-Type failed: " + $_.Exception.Message) -Type Error
    throw
}

function Get-ReaderNames {
    param(
        $Context,
        [string[]]$ApprovedVendors = @('HID', 'Identiv', 'Gemalto', 'Thales')
    )

    [int]$length = 0
    $result = [PCSC]::SCardListReaders($Context, $null, [IntPtr]::Zero, [ref]$length)
    if ($result -ne 0 -or $length -le 2) { return $null }

    # Allocate buffer and read multi-string list (names separated by nulls)
    # pcchReaders returns character count for Unicode; allocate bytes = chars * 2
    $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length * 2)
    try {
        $result = [PCSC]::SCardListReaders($Context, $null, $buffer, [ref]$length)
        if ($result -ne 0) { return $null }

        # Convert pointer to Unicode string using character count
        $raw = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($buffer, $length)
        $names = $raw -split "`0" | Where-Object { $_.Trim().Length -gt 0 }
        if (-not $names -or $names.Count -eq 0) { return $null }

        # Return vendor-preferred ordering
        $preferred = @()
        foreach ($n in $names) {
            if ($ApprovedVendors | Where-Object { $n.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -ge 0 }) {
                $preferred += $n
            }
        }
        $others = $names | Where-Object { $preferred -notcontains $_ }
        return ($preferred + $others)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
    }
}

function Test-CardPresent {
    param($Context, $ReaderName)

    [IntPtr]$hCard = [IntPtr]::Zero
    [int]$protocol = 0

    try {
        # Try to connect to the card
        $result = [PCSC]::SCardConnect($Context, $ReaderName, [PCSC]::SCARD_SHARE_SHARED,
            ([PCSC]::SCARD_PROTOCOL_T0 -bor [PCSC]::SCARD_PROTOCOL_T1),
            [ref]$hCard, [ref]$protocol)

        if ($result -eq 0) {
            [void][PCSC]::SCardDisconnect($hCard, [PCSC]::SCARD_LEAVE_CARD)
            return $true
        }

        return $false
    }
    catch {
        if ($hCard -ne [IntPtr]::Zero) {
            try { [void][PCSC]::SCardDisconnect($hCard, [PCSC]::SCARD_LEAVE_CARD) } catch {}
        }
        return $false
    }
}

function Get-IdleTime {
    $lastInput = New-Object LASTINPUTINFO
    $lastInput.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lastInput)

    if ([IdleTime]::GetLastInputInfo([ref]$lastInput)) {
        $idleMilliseconds = ([Environment]::TickCount - $lastInput.dwTime)
        return [TimeSpan]::FromMilliseconds($idleMilliseconds)
    }

    return [TimeSpan]::Zero
}

function Show-OutlookCloseDialog {
    param(
        [string]$Reason,
        [int]$TimeoutSeconds = 10
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    }
    catch {
        Write-CacEvent -Id 9002 -Message ("Failed to load Windows.Forms: " + $_.Exception.Message) -Type Error
        throw
    }

    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(400, 230)
    $form.Text = 'CAC Card Removed'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(360, 110)
    $label.AutoSize = $false
    $form.Controls.Add($label)

    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(80, 140)
    $yesButton.Size = New-Object System.Drawing.Size(100, 35)
    $yesButton.Text = '&Yes'
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($yesButton)
    $form.AcceptButton = $yesButton

    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(220, 140)
    $noButton.Size = New-Object System.Drawing.Size(100, 35)
    $noButton.Text = '&No'
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($noButton)
    $form.CancelButton = $noButton

    # Countdown timer that updates every second
    $script:countdown = $TimeoutSeconds
    $baseText = "$Reason`n`nDo you want to close Outlook? (Press Y or N)`n`nClosing in"

    $countdownTimer = New-Object System.Windows.Forms.Timer
    $countdownTimer.Interval = 1000  # 1 second
    $countdownTimer.Add_Tick({
            $script:countdown--
            if ($script:countdown -gt 0) {
                $label.Text = "$baseText $($script:countdown) seconds..."
            }
            else {
                $countdownTimer.Stop()
                $form.DialogResult = [System.Windows.Forms.DialogResult]::None
                $form.Close()
            }
        })
    $countdownTimer.Start()

    # Update initial label with countdown
    $label.Text = "$baseText $($script:countdown) seconds..."

    $result = $form.ShowDialog()
    $countdownTimer.Stop()
    $countdownTimer.Dispose()
    $form.Dispose()

    return $result
}

# Ensure STA for Windows Forms dialogs
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "Restarting script in STA mode for dialogs..." -ForegroundColor Yellow
    Write-CacEvent -Id 9003 -Message "Restarting in STA due to MTA apartment state" -Type Warning
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Get-Process -Id $PID).Path
    $psi.Arguments = "-STA -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

# Establish context
[IntPtr]$context = [IntPtr]::Zero
$result = [PCSC]::SCardEstablishContext([PCSC]::SCARD_SCOPE_USER, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$context)
if ($result -ne 0) {
    Write-Host "Error: Failed to establish context (0x$($result.ToString('X8')))" -ForegroundColor Red
    exit 1
}

try {
    # Get reader names and probe for an active reader
    $readers = Get-ReaderNames -Context $context
    if (-not $readers) {
        Write-Host "Error: No card reader found!" -ForegroundColor Red
        exit 1
    }

    $reader = $null
    foreach ($r in $readers) {
        if (Test-CardPresent -Context $context -ReaderName $r) { $reader = $r; break }
    }
    if (-not $reader) { $reader = $readers[0] }

    Write-Host "Using reader: $reader" -ForegroundColor Gray

    # Wait for card to be present
    if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD REMOVED  ***" -ForegroundColor Red -BackgroundColor Yellow
        Write-CacEvent -Id 1001 -Message "Initial state: CARD REMOVED" -Type Information
        [Console]::ResetColor()
        Write-Host "Waiting for card to be inserted... (Press Ctrl+C to exit)" -ForegroundColor Yellow

        while (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Start-Sleep -Milliseconds 500
        }
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
        Write-CacEvent -Id 1002 -Message "State change: CARD INSERTED" -Type Information
        [Console]::ResetColor()
        Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green
    }
    else {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
        Write-CacEvent -Id 1003 -Message "Initial state: CARD INSERTED" -Type Information
        [Console]::ResetColor()
        Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green
    }

    # Configuration
    $idleThresholdMinutes = 120  # For testing: 20 minutes (normally: 2 hours = 120 minutes)
    $idleThresholdHours = $idleThresholdMinutes / 60
    $cardPresentPollMs = 500
    $cardRemovedPollMs = 5000  # 10x slower when card removed

    # Poll for card removal
    while ($true) {
        Start-Sleep -Milliseconds $cardPresentPollMs

        if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
            Write-Host "*** CARD REMOVED  ***" -ForegroundColor Red -BackgroundColor Yellow
            Write-CacEvent -Id 1004 -Message "State change: CARD REMOVED" -Type Warning
            [Console]::ResetColor()

            # Show popup for immediate response
            $result = Show-OutlookCloseDialog -Reason "CAC card removed!" -TimeoutSeconds 10

            # Handle immediate response
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "User clicked Yes - checking for Outlook..." -ForegroundColor Yellow
                Write-CacEvent -Id 2001 -Message "User confirmed Outlook close (card removed)" -Type Information

                $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                if ($outlookProcess) {
                    Write-Host "Closing Outlook (graceful)..." -ForegroundColor Yellow
                    $closed = $false
                    try {
                        $olApp = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
                        if ($olApp) {
                            $olApp.Quit()
                            Start-Sleep -Seconds 2
                            $closed = -not (Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue)
                        }
                    }
                    catch {}
                    if (-not $closed) {
                        if ($AllowForceKill) {
                            Write-Host "Graceful close failed; force-closing Outlook..." -ForegroundColor Yellow
                            Write-CacEvent -Id 2003 -Message "Force-closing Outlook after graceful attempt failed" -Type Warning
                            Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
                            Write-Host "Outlook closed (force)." -ForegroundColor Green
                        }
                        else {
                            Write-Host "Graceful close did not complete; leaving Outlook running (policy disallows force-kill)." -ForegroundColor DarkYellow
                            Write-CacEvent -Id 2004 -Message "Graceful close failed; force-kill disallowed by policy" -Type Warning
                        }
                    }
                    else {
                        Write-Host "Outlook closed (graceful)." -ForegroundColor Green
                        Write-CacEvent -Id 2002 -Message "Outlook closed gracefully" -Type Information
                    }
                }
                else {
                    Write-Host "Outlook is not running." -ForegroundColor Gray
                    Write-CacEvent -Id 2005 -Message "Outlook not running at user prompt" -Type Information
                }

                # Exit after closing Outlook
                Write-Host "Exiting monitor." -ForegroundColor Cyan
                break
            }
            elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Write-Host "User clicked No - continuing monitoring." -ForegroundColor Gray
                Write-CacEvent -Id 2006 -Message "User declined Outlook close" -Type Information
            }
            else {
                Write-Host "Timeout - no action taken." -ForegroundColor Gray
                Write-CacEvent -Id 2007 -Message "Prompt timeout; no action" -Type Information
            }

            # Wait for card to be reinserted, checking idle time periodically
            Write-Host "Waiting for card to be reinserted... (Press Ctrl+C to exit)" -ForegroundColor Yellow
            Write-Host "Auto-close Outlook after $idleThresholdMinutes minutes of idle time" -ForegroundColor DarkGray

            $cardRemovalTime = Get-Date
            $idleWarningShown = $false
            $statusUpdateInterval = [math]::Max(5, [math]::Floor($idleThresholdMinutes / 4))  # Update 4 times during countdown (min 5 minutes)
            $lastStatusUpdate = Get-Date

            while (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
                Start-Sleep -Milliseconds $cardRemovedPollMs

                # Check idle time
                $idleTime = Get-IdleTime
                $timeSinceRemoval = (Get-Date) - $cardRemovalTime
                $timeSinceLastUpdate = ((Get-Date) - $lastStatusUpdate).TotalMinutes

                # Check if we've exceeded the idle threshold
                if ($idleTime.TotalMinutes -ge $idleThresholdMinutes) {
                    Write-Host "`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Idle threshold reached: " -ForegroundColor Gray -NoNewline
                    Write-Host "$([math]::Round($idleTime.TotalMinutes, 1)) minutes idle" -ForegroundColor Yellow

                    # Show auto-close warning
                    $result = Show-OutlookCloseDialog -Reason "System idle for $idleThresholdMinutes minutes!`nCAC card still removed!" -TimeoutSeconds 10

                    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                        Write-Host "User clicked Yes - checking for Outlook..." -ForegroundColor Yellow
                        Write-CacEvent -Id 2101 -Message "User confirmed Outlook close (idle threshold)" -Type Information

                        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                        if ($outlookProcess) {
                            Write-Host "Closing Outlook (graceful)..." -ForegroundColor Yellow
                            $closed = $false
                            try {
                                $olApp = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
                                if ($olApp) {
                                    $olApp.Quit()
                                    Start-Sleep -Seconds 2
                                    $closed = -not (Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue)
                                }
                            }
                            catch {}
                            if (-not $closed) {
                                if ($AllowForceKill) {
                                    Write-Host "Graceful close failed; force-closing Outlook..." -ForegroundColor Yellow
                                    Write-CacEvent -Id 2103 -Message "Force-closing Outlook after graceful attempt failed (idle)" -Type Warning
                                    Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
                                    Write-Host "Outlook closed (force)." -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Graceful close did not complete; leaving Outlook running (policy disallows force-kill)." -ForegroundColor DarkYellow
                                    Write-CacEvent -Id 2104 -Message "Graceful close failed; force-kill disallowed by policy (idle)" -Type Warning
                                }
                            }
                            else {
                                Write-Host "Outlook closed (graceful)." -ForegroundColor Green
                                Write-CacEvent -Id 2102 -Message "Outlook closed gracefully (idle)" -Type Information
                            }
                        }
                        else {
                            Write-Host "Outlook is not running." -ForegroundColor Gray
                            Write-CacEvent -Id 2105 -Message "Outlook not running at idle prompt" -Type Information
                        }

                        Write-Host "Exiting monitor." -ForegroundColor Cyan
                        return
                    }
                    elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                        Write-Host "User clicked No - resetting idle timer." -ForegroundColor Gray
                        Write-CacEvent -Id 2106 -Message "User declined Outlook close at idle threshold; reset timer" -Type Information
                        # Reset the removal time to give another idle period
                        $cardRemovalTime = Get-Date
                        $lastStatusUpdate = Get-Date
                    }
                    else {
                        # Timeout - auto-close and exit
                        Write-Host "Timeout - auto-closing Outlook and exiting..." -ForegroundColor Yellow
                        Write-CacEvent -Id 2107 -Message "Idle prompt timeout; auto-close policy" -Type Warning

                        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                        if ($outlookProcess) {
                            Write-Host "Closing Outlook (graceful)..." -ForegroundColor Yellow
                            $closed = $false
                            try {
                                $olApp = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
                                if ($olApp) {
                                    $olApp.Quit()
                                    Start-Sleep -Seconds 2
                                    $closed = -not (Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue)
                                }
                            }
                            catch {}
                            if (-not $closed) {
                                if ($AllowForceKill) {
                                    Write-Host "Graceful close failed; force-closing Outlook..." -ForegroundColor Yellow
                                    Write-CacEvent -Id 2108 -Message "Force-closing Outlook after graceful attempt failed (auto-close)" -Type Warning
                                    Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
                                    Write-Host "Outlook closed (force)." -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Graceful close did not complete; leaving Outlook running (policy disallows force-kill)." -ForegroundColor DarkYellow
                                    Write-CacEvent -Id 2109 -Message "Graceful close failed; force-kill disallowed by policy (auto-close)" -Type Warning
                                }
                            }
                            else {
                                Write-Host "Outlook closed (graceful)." -ForegroundColor Green
                                Write-CacEvent -Id 2110 -Message "Outlook closed gracefully (auto-close)" -Type Information
                            }
                        }
                        else {
                            Write-Host "Outlook is not running." -ForegroundColor Gray
                            Write-CacEvent -Id 2111 -Message "Outlook not running at auto-close" -Type Information
                        }

                        Write-Host "Exiting monitor." -ForegroundColor Cyan
                        return
                    }
                }

                # Show periodic status update
                if ($timeSinceLastUpdate -ge $statusUpdateInterval) {
                    $remainingMinutes = [math]::Max(0, $idleThresholdMinutes - $idleTime.TotalMinutes)
                    if ($remainingMinutes -gt 0) {
                        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Idle: $([math]::Round($idleTime.TotalMinutes, 1)) min | Auto-close in: $([math]::Round($remainingMinutes, 1)) min" -ForegroundColor DarkGray
                        $lastStatusUpdate = Get-Date
                    }
                }
            }

            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
            Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
            Write-CacEvent -Id 1005 -Message "State change: CARD INSERTED (after removal)" -Type Information
            [Console]::ResetColor()
            Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green

            # Give a brief moment for the card to settle, then check immediately
            Start-Sleep -Milliseconds 100
        }
    }
}
finally {
    # Cleanup
    [void][PCSC]::SCardReleaseContext($context)
}