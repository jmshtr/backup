# Load configuration from JSON file
try {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "backup_config.json"
    $config = Get-Content -Path $configPath -ErrorAction Stop | ConvertFrom-Json
}
catch {
    Invoke-ErrorHandling -ErrorMessage "Failed to load configuration from JSON file: $_"
}

# Destination backup location
$backupLocation = $config.Destination

# Error handling function
function Invoke-ErrorHandling {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    # Log error to a log file
    $ErrorLogPath = Join-Path -Path $PSScriptRoot -ChildPath "error.log"
    $ErrorMessage | Out-File -FilePath $ErrorLogPath -Append
    exit 1
}

# Check if backup location exists, create if not
if (-not (Test-Path -Path $backupLocation)) {
    try {
        New-Item -ItemType Directory -Path $backupLocation -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Invoke-ErrorHandling -ErrorMessage "Failed to create backup location: $_"
    }
}

# Check if last backup file exists, create if not
$lastBackupPath = Join-Path -Path $backupLocation -ChildPath "last_backup.txt"
if (-not (Test-Path -Path $lastBackupPath)) {
    try {
        New-Item -ItemType File -Path $lastBackupPath -ErrorAction Stop | Out-Null
    }
    catch {
        Invoke-ErrorHandling -ErrorMessage "Failed to create last backup file: $_"
    }
}

# Get last backup timestamp
try {
    $lastBackup = Get-Item -Path $lastBackupPath -ErrorAction Stop
}
catch {
    Invoke-ErrorHandling -ErrorMessage "Failed to retrieve last backup timestamp: $_"
}

# Function to perform backup
function PerformBackup {
    # Iterate through files/directories to backup
    foreach ($item in $config.FilesToBackup) {
        $source = $item.Source
        $destination = Join-Path -Path $backupLocation -ChildPath $item.Destination
        
        # Check if item has been modified since last backup
        if ((Get-Item $source).LastWriteTime -gt $lastBackup.LastWriteTime) {
            # Perform backup
            try {
                Copy-Item -Path $source -Destination $destination -Recurse -Force -ErrorAction Stop
            }
            catch {
                Invoke-ErrorHandling -ErrorMessage "Failed to copy item from $source to $destination."
            }
        }
    }
    
    # Update last backup timestamp
    try {
        Get-Date | Out-File -FilePath $lastBackupPath -ErrorAction Stop
    }
    catch {
        Invoke-ErrorHandling -ErrorMessage "Failed to update last backup timestamp: $_"
    }
}

# Perform backup
PerformBackup
