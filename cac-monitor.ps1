# CAC Card Reader Monitor - Simple Detection Script
# Must run in Windows PowerShell to access Smart Card APIs

Write-Host "CAC Monitor - Starting..." -ForegroundColor Cyan

# Define PC/SC (Smart Card) API - Simplified version
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
        Write-Host "Waiting for card to be inserted..." -ForegroundColor Yellow

        while (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Start-Sleep -Milliseconds 500
        }

        Write-Host "Card inserted!" -ForegroundColor Green
    } else {
        Write-Host "Card already present!" -ForegroundColor Green
    }

    Write-Host "Monitoring for card removal... (Press Ctrl+C to exit)" -ForegroundColor Green

    # Poll for card removal
    while ($true) {
        Start-Sleep -Milliseconds 500

        if (-not (Test-CardPresent -Context $context -ReaderName $reader)) {
            Write-Host ""
            Write-Host "*** CARD REMOVED! ***" -ForegroundColor Red -BackgroundColor Yellow
            Write-Host ""
            break
        }
    }
} finally {
    # Cleanup
    [void][PCSC]::SCardReleaseContext($context)
}