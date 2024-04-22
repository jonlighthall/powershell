Add-Type -AssemblyName System.Windows.Forms 

while ($true) {
    $originalPosition = [System.Windows.Forms.Cursor]::Position
    $newX = $originalPosition.X + (Get-Random -Minimum -5 -Maximum 5)
    $newY = $originalPosition.Y + (Get-Random -Minimum -5 -Maximum 5)
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)
    Start-Sleep -Seconds 3 
}