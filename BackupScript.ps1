# Load configuration from JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "backup_config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Destination backup location
$backupLocation = $config.Destination

# Check if backup location exists, create if not
if (-not (Test-Path -Path $backupLocation)) {
    New-Item -ItemType Directory -Path $backupLocation -Force | Out-Null
}

# Check if last backup file exists, create if not
$lastBackupPath = Join-Path -Path $backupLocation -ChildPath "last_backup.txt"
if (-not (Test-Path -Path $lastBackupPath)) {
    New-Item -ItemType File -Path $lastBackupPath | Out-Null
}

# Get last backup timestamp
$lastBackup = Get-Item -Path $lastBackupPath

# Function to perform backup
function PerformBackup {
    # Iterate through files/directories to backup
    foreach ($item in $config.FilesToBackup) {
        $source = $item.Source
        $destination = Join-Path -Path $backupLocation -ChildPath $item.Destination
        
        # Check if item has been modified since last backup
        if ((Get-Item $source).LastWriteTime -gt $lastBackup.LastWriteTime) {
            # Perform backup
            Copy-Item -Path $source -Destination $destination -Recurse -Force
        }
    }
    
    # Update last backup timestamp
    Get-Date | Out-File -FilePath $lastBackupPath
}

# Perform backup
PerformBackup
