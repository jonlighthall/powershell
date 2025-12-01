# CAC Card Reader Monitor - Simple Detection Script
# Must run in Windows PowerShell to access Smart Card APIs

Write-Host "CAC Monitor - Starting..." -ForegroundColor Cyan

# Define PC/SC (Smart Card) API and Idle Time Tracking
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

function Get-ReaderName {
    param($Context)

    [int]$length = 0
    $result = [PCSC]::SCardListReaders($Context, $null, [IntPtr]::Zero, [ref]$length)
    if ($result -ne 0 -or $length -le 2) { return $null }

    # Allocate buffer
    $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length * 2)  # *2 for Unicode
    try {
        $result = [PCSC]::SCardListReaders($Context, $null, $buffer, [ref]$length)
        if ($result -ne 0) { return $null }

        # Read as Unicode string
        $text = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($buffer)

        return $text
    } finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
    }
}function Test-CardPresent {
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
    } catch {
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

    Add-Type -AssemblyName System.Windows.Forms

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
        } else {
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

# Establish context
[IntPtr]$context = [IntPtr]::Zero
$result = [PCSC]::SCardEstablishContext([PCSC]::SCARD_SCOPE_USER, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$context)
if ($result -ne 0) {
    Write-Host "Error: Failed to establish context (0x$($result.ToString('X8')))" -ForegroundColor Red
    exit 1
}

try {
    # Get reader name
    $reader = Get-ReaderName -Context $context
    if (-not $reader) {
        Write-Host "Error: No card reader found!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Found reader: $reader" -ForegroundColor Gray

    # Wait for card to be present
    if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD REMOVED  ***" -ForegroundColor Red -BackgroundColor Yellow
        [Console]::ResetColor()
        Write-Host "Waiting for card to be inserted... (Press Ctrl+C to exit)" -ForegroundColor Yellow

        while (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Start-Sleep -Milliseconds 500
        }
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
        [Console]::ResetColor()
        Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green
    } else {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
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
            [Console]::ResetColor()

            # Show popup for immediate response
            $result = Show-OutlookCloseDialog -Reason "CAC card removed!" -TimeoutSeconds 10

            # Handle immediate response
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "User clicked Yes - checking for Outlook..." -ForegroundColor Yellow

                $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                if ($outlookProcess) {
                    Write-Host "Closing Outlook..." -ForegroundColor Yellow
                    Stop-Process -Name "OUTLOOK" -Force
                    Write-Host "Outlook closed." -ForegroundColor Green
                } else {
                    Write-Host "Outlook is not running." -ForegroundColor Gray
                }

                # Exit after closing Outlook
                Write-Host "Exiting monitor." -ForegroundColor Cyan
                break
            } elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Write-Host "User clicked No - continuing monitoring." -ForegroundColor Gray
            } else {
                Write-Host "Timeout - no action taken." -ForegroundColor Gray
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

                        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                        if ($outlookProcess) {
                            Write-Host "Closing Outlook..." -ForegroundColor Yellow
                            Stop-Process -Name "OUTLOOK" -Force
                            Write-Host "Outlook closed." -ForegroundColor Green
                        } else {
                            Write-Host "Outlook is not running." -ForegroundColor Gray
                        }

                        Write-Host "Exiting monitor." -ForegroundColor Cyan
                        return
                    } elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                        Write-Host "User clicked No - resetting idle timer." -ForegroundColor Gray
                        # Reset the removal time to give another idle period
                        $cardRemovalTime = Get-Date
                        $lastStatusUpdate = Get-Date
                    } else {
                        # Timeout - auto-close and exit
                        Write-Host "Timeout - auto-closing Outlook and exiting..." -ForegroundColor Yellow

                        $outlookProcess = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue
                        if ($outlookProcess) {
                            Write-Host "Closing Outlook..." -ForegroundColor Yellow
                            Stop-Process -Name "OUTLOOK" -Force
                            Write-Host "Outlook closed." -ForegroundColor Green
                        } else {
                            Write-Host "Outlook is not running." -ForegroundColor Gray
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
            [Console]::ResetColor()
            Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green

            # Give a brief moment for the card to settle, then check immediately
            Start-Sleep -Milliseconds 100
        }
    }
} finally {
    # Cleanup
    [void][PCSC]::SCardReleaseContext($context)
}