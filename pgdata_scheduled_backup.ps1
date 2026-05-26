# Scheduled Clean Backup Script for HikCentral PGData
# Stops services, backs up PGData, restarts services
# Save as: C:\Users\server\scripts\BackupPgdata_Scheduled.ps1

$sourceFolder = "C:\Program Files (x86)\HikCentral\VSM Servers\PGData"
$backupDestination = "C:\Users\ecusf\OneDrive\Documents\HikCentral-Backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFolder = Join-Path $backupDestination "PGData_$timestamp"
$logFile = Join-Path $backupDestination "backup_log.txt"

$hikServices = @(
    "3rd Party Device Access Gateway",
    "BACnetGateway",
    "BeeAgent",
    "Extended Device Access Service",
    "OpenDataServer",
    "SADPServer",
    "SIAGateway",
    "STREAM",
    "SurgardGateway",
    "SYS",
    "CommonHKFPModuleSvr",
    "Nginx",
    "Nginx1",
    "Nginx2",
    "Nginx3",
    "Nginx4",
    "Nginx5"
)

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

try {
    Write-Log "=== Scheduled Backup started ==="

    # Step 1 - Stop all HikCentral services
    Write-Log "Stopping HikCentral services..."
    foreach ($svc in $hikServices) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s -and $s.Status -eq "Running") {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Write-Log "Stopped: $svc"
        }
    }
    Start-Sleep -Seconds 5

    # Step 2 - Disable and stop PostgreSQL
    Write-Log "Stopping PostgreSQL..."
    sc.exe config PostgreSQL start= disabled | Out-Null
    net stop PostgreSQL | Out-Null
    Start-Sleep -Seconds 5
    Write-Log "PostgreSQL stopped."

    # Step 3 - Copy PGData
    Write-Log "Copying PGData to: $backupFolder"
    & robocopy $sourceFolder $backupFolder /E /COPY:DAT /R:3 /W:5 /ZB | Out-Null
    Write-Log "Backup completed successfully: PGData_$timestamp"

    # Step 4 - Keep only last 2 backups
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
    # Step 5 - Re-enable and start PostgreSQL
    Write-Log "Starting PostgreSQL..."
    sc.exe config PostgreSQL start= demand | Out-Null
    net start PostgreSQL | Out-Null
    Start-Sleep -Seconds 5

    # Step 6 - Restart all HikCentral services
    Write-Log "Restarting HikCentral services..."
    foreach ($svc in $hikServices) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-Log "Started: $svc"
        }
    }
    Write-Log "All services restarted."
    Write-Log "=== Scheduled Backup finished ==="
}