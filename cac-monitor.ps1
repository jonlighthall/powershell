<#
.SYNOPSIS
    CAC Card Reader Monitor - Monitors smart card insertion/removal and auto-closes Outlook after idle timeout.

.DESCRIPTION
    This script monitors CAC (Common Access Card) smart card readers and tracks system idle time.
    When the CAC card is removed and the system has been idle for a configurable period, it will:
    - Prompt the user to close Outlook (with countdown timer)
    - Auto-close Outlook if no response (timeout)
    - Display a notification so the user knows what happened when they return

    Primary use case: Terminate Outlook overnight when computer is locked and CAC removed.

.REQUIREMENTS
    - Windows PowerShell (not PowerShell Core) for Smart Card API access
    - PC/SC compatible smart card reader
    - Runs in STA mode for Windows Forms dialogs (auto-restarts if needed)

.NOTES
    Author: Jon Lighthall
    No external module dependencies - uses only built-in Windows APIs.
#>

# === CONFIGURATION ===
# Adjust these values to customize behavior

$IdleThresholdMinutes = 120      # Auto-close Outlook after this many minutes idle (default: 2 hours)
$CardPresentPollMs = 500         # How often to check for card removal when card is present (ms)
$CardRemovedPollMs = 5000        # How often to check for card insertion when card is removed (ms)
$DialogTimeoutSeconds = 10       # Seconds before auto-close dialog times out
$AllowForceKill = $false         # If $true, force-kill Outlook when graceful close fails

# === END CONFIGURATION ===

Write-Host "CAC Monitor - Starting..." -ForegroundColor Cyan

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
        # Force array return to prevent string iteration
        $result = @($preferred) + @($others)
        return , $result
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

function Show-OutlookClosedNotification {
    param(
        [string]$Message
    )

    # Simple MessageBox - no external dependencies, works on all Windows systems
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Message, "CAC Monitor - Outlook Closed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
    catch {
        # Silently ignore - notification is non-critical
    }
}

function Close-OutlookGracefully {
    param(
        [bool]$AllowForceKill = $false
    )

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
                Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
                Write-Host "Outlook closed (force)." -ForegroundColor Green
            }
            else {
                Write-Host "Graceful close did not complete; leaving Outlook running (policy disallows force-kill)." -ForegroundColor DarkYellow
            }
        }
        else {
            Write-Host "Outlook closed (graceful)." -ForegroundColor Green
        }
        return $true
    }
    else {
        Write-Host "Outlook is not running." -ForegroundColor Gray
        return $false
    }
}

function Show-OutlookCloseDialog {
    param(
        [string]$Reason,
        [int]$TimeoutSeconds = $script:DialogTimeoutSeconds
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    }
    catch {
        throw
    }

    # Enable modern Windows visual styles (otherwise looks like Windows 95)
    [System.Windows.Forms.Application]::EnableVisualStyles()

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

function Wait-ForCardWithIdleMonitoring {
    param(
        $Context,
        $ReaderName,
        [int]$IdleThresholdMinutes,
        [int]$PollMs = $script:CardRemovedPollMs,
        [string]$DialogReason = "CAC card removed!",
        [bool]$AllowForceKill = $script:AllowForceKill,
        [bool]$ShowInitialPrompt = $false
    )

    # Show initial prompt if requested (when card is removed during monitoring)
    if ($ShowInitialPrompt) {
        $result = Show-OutlookCloseDialog -Reason $DialogReason -TimeoutSeconds 10
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Write-Host "User clicked Yes - checking for Outlook..." -ForegroundColor Yellow
            Close-OutlookGracefully -AllowForceKill $AllowForceKill
            Write-Host "Exiting monitor." -ForegroundColor Cyan
            return "exit"
        }
        elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
            Write-Host "User clicked No - continuing monitoring." -ForegroundColor Gray
        }
        else {
            Write-Host "Timeout - no action taken." -ForegroundColor Gray
        }
    }

    Write-Host "Waiting for card to be inserted... (Press Ctrl+C to exit)" -ForegroundColor Yellow
    Write-Host "Outlook will auto-close after $IdleThresholdMinutes minutes of idle time" -ForegroundColor DarkGray

    # Idle tracking variables
    $idleInterval = $IdleThresholdMinutes * 0.25
    $lastIdleThresholdCrossed = 0
    $peakIdleMinutes = 0
    $wasSignificantlyIdle = $false

    # Print initial auto-close timer
    $idleTime = Get-IdleTime
    $remainingMinutes = [math]::Max(0, $IdleThresholdMinutes - $idleTime.TotalMinutes)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Auto-close in $([math]::Round($remainingMinutes, 1)) min..." -ForegroundColor DarkGray

    while (-not (Test-CardPresent -Context $Context -ReaderName $ReaderName)) {
        Start-Sleep -Milliseconds $PollMs

        $idleTime = Get-IdleTime
        $currentIdleMinutes = $idleTime.TotalMinutes

        # Track peak idle time
        if ($currentIdleMinutes -gt $peakIdleMinutes) {
            $peakIdleMinutes = $currentIdleMinutes
        }

        # Detect when user becomes active after significant idle
        if ($wasSignificantlyIdle -and $currentIdleMinutes -lt $idleInterval) {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Activity detected after $([math]::Round($peakIdleMinutes, 1)) min idle - auto-close timer reset" -ForegroundColor DarkGray
            $lastIdleThresholdCrossed = 0
            $peakIdleMinutes = 0
            $wasSignificantlyIdle = $false
        }

        # Show progress at 25%, 50%, 75% thresholds
        $currentThreshold = [math]::Floor($currentIdleMinutes / $idleInterval)
        if ($currentThreshold -gt $lastIdleThresholdCrossed -and $currentThreshold -lt 4 -and $currentIdleMinutes -lt $IdleThresholdMinutes) {
            $remainingMinutes = [math]::Max(0, $IdleThresholdMinutes - $currentIdleMinutes)
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Idle: $([math]::Round($currentIdleMinutes, 1)) min | Auto-close in: $([math]::Round($remainingMinutes, 1)) min" -ForegroundColor DarkGray
            $lastIdleThresholdCrossed = $currentThreshold
            $wasSignificantlyIdle = $true
        }

        # Check if idle threshold reached
        if ($idleTime.TotalMinutes -ge $IdleThresholdMinutes) {
            Write-Host "`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Idle threshold reached: " -ForegroundColor Gray -NoNewline
            Write-Host "$([math]::Round($idleTime.TotalMinutes, 1)) minutes idle" -ForegroundColor Yellow

            $result = Show-OutlookCloseDialog -Reason "System idle for $IdleThresholdMinutes minutes!`nCAC card not inserted!" -TimeoutSeconds 10

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "User clicked Yes - checking for Outlook..." -ForegroundColor Yellow
                Close-OutlookGracefully -AllowForceKill $AllowForceKill
                Write-Host "Exiting monitor." -ForegroundColor Cyan
                return "exit"
            }
            elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Write-Host "User clicked No - resetting idle timer." -ForegroundColor Gray
                $lastIdleThresholdCrossed = 0
                $peakIdleMinutes = 0
                $wasSignificantlyIdle = $false
            }
            else {
                # Timeout - auto-close
                Write-Host "Timeout - auto-closing Outlook and exiting..." -ForegroundColor Yellow
                Close-OutlookGracefully -AllowForceKill $AllowForceKill
                Show-OutlookClosedNotification -Message "Outlook closed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') after $IdleThresholdMinutes minutes of inactivity with CAC removed."
                Write-Host "Exiting monitor." -ForegroundColor Cyan
                return "exit"
            }
        }
    }

    return "card_inserted"
}

# Ensure STA for Windows Forms dialogs
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "Restarting script in STA mode for dialogs..." -ForegroundColor Yellow
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
    # Ensure we iterate array elements, not string characters
    foreach ($r in @($readers)) {
        if (Test-CardPresent -Context $context -ReaderName $r) { $reader = $r; break }
    }
    if (-not $reader) { $reader = @($readers)[0] }

    Write-Host "Using reader: $reader" -ForegroundColor Gray

    # Initial state check
    if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD REMOVED  ***" -ForegroundColor Red -BackgroundColor Yellow
        [Console]::ResetColor()

        $waitResult = Wait-ForCardWithIdleMonitoring -Context $context -ReaderName $reader `
            -IdleThresholdMinutes $IdleThresholdMinutes
        if ($waitResult -eq "exit") { return }

        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
        [Console]::ResetColor()
    }
    else {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initial state: " -ForegroundColor Gray -NoNewline
        Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
        [Console]::ResetColor()
    }

    Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green

    # Main monitoring loop
    while ($true) {
        Start-Sleep -Milliseconds $CardPresentPollMs

        if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
            Write-Host "*** CARD REMOVED  ***" -ForegroundColor Red -BackgroundColor Yellow
            [Console]::ResetColor()

            $waitResult = Wait-ForCardWithIdleMonitoring -Context $context -ReaderName $reader `
                -IdleThresholdMinutes $IdleThresholdMinutes -ShowInitialPrompt $true
            if ($waitResult -eq "exit") { break }

            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] State change:  " -ForegroundColor Gray -NoNewline
            Write-Host "*** CARD INSERTED ***" -ForegroundColor Green -BackgroundColor Yellow
            [Console]::ResetColor()
            Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green
        }
    }
}
finally {
    # Cleanup
    [void][PCSC]::SCardReleaseContext($context)
}