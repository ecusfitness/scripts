# Manual Shadow Copy Backup for HikCentral PGData
# Save as: C:\Scripts\BackupPgdata_ShadowCopy.ps1

$sourceFolder = "C:\Program Files (x86)\HikCentral\VSM Servers\PGData"
$backupDestination = "C:\Users\ecusf\OneDrive\Documents\HikCentral-Backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFolder = Join-Path $backupDestination "PGData_$timestamp"
$logFile = Join-Path $backupDestination "backup_log.txt"

function Write-Log {
    param($message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    Write-Host $entry
    Add-Content -Path $logFile -Value $entry
}

# Create backup destination if it doesn't exist
if (-not (Test-Path $backupDestination)) {
    New-Item -ItemType Directory -Path $backupDestination -Force | Out-Null
}

Write-Log "=== Shadow Copy Backup started ==="

# Create shadow copy
Write-Log "Creating shadow copy..."
$shadowCopy = (Get-WmiObject -List Win32_ShadowCopy).Create("C:\", "ClientAccessible")
$shadowId = $shadowCopy.ShadowID
$shadowDevice = (Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $shadowId }).DeviceObject

# Create symbolic link to shadow copy
$shadowLink = "C:\ShadowCopyLink"
if (Test-Path $shadowLink) {
    cmd /c rmdir $shadowLink
}
cmd /c mklink /d $shadowLink "$shadowDevice\"
Write-Log "Shadow copy created."

try {
    $shadowSource = $shadowLink + $sourceFolder.Substring(2)
    Write-Log "Copying from: $shadowSource"
    Write-Log "Destination: $backupFolder"

    & robocopy $shadowSource $backupFolder /E /COPY:DAT /R:3 /W:5 /ZB | Out-Null
    Write-Log "Shadow copy backup completed: PGData_$timestamp"

    # Keep only last 2 backups
    Write-Log "Cleaning old backups..."
    Get-ChildItem $backupDestination -Directory |
        Where-Object { $_.Name -like "PGData_*" } |
        Sort-Object CreationTime -Descending |
        Select-Object -Skip 2 |
        ForEach-Object {
            Write-Log "Deleting old backup: $($_.Name)"
            Remove-Item $_.FullName -Recurse -Force
        }
    Write-Log "Cleanup done. Kept last 2 backups."

} catch {
    Write-Log "ERROR: $_"

} finally {
    # Clean up shadow copy and symbolic link
    Write-Log "Cleaning up shadow copy..."
    cmd /c rmdir $shadowLink
    Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $shadowId } | ForEach-Object { $_.Delete() }
    Write-Log "Shadow copy removed."
    Write-Log "=== Shadow Copy Backup finished ==="
}