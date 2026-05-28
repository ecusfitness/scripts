# Weekly System Restore Point Script
# Save as: C:\Users\server\scripts\restore_point_weekly.ps1

function Write-Log {
    param($message)
    $logFile = "C:\Users\server\scripts\restore_point_log.txt"
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    Write-Host $entry
    Add-Content -Path $logFile -Value $entry
}

Write-Log "=== Creating System Restore Point ==="

try {
    $description = "HikCentral Weekly Backup - $(Get-Date -Format 'yyyy-MM-dd')"
    Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
    Write-Log "Restore point created successfully: $description"
} catch {
    Write-Log "ERROR: $_"
}

Write-Log "=== Restore Point script finished ==="