param (
    [string]$ConfigPath = ".\backup_config.json",
    [string]$BackupLocation = "C:\Backup"
)

# Function to log messages
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$LogPath = (Join-Path -Path $PSScriptRoot -ChildPath "backup.log")
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$TimeStamp - $Message" | Out-File -FilePath $LogPath -Append
}

# Error handling function
function Handle-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )
    Write-Log -Message "Error: $ErrorMessage"
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    exit 1
}

# Validate configuration file structure
try {
    $config = Get-Content -Path $ConfigPath -ErrorAction Stop | ConvertFrom-Json
} catch {
    Handle-Error -ErrorMessage "Failed to load configuration file: $_"
}

if (-not ($config | Get-Member -MemberType NoteProperty -Name "Destination")) {
    Handle-Error -ErrorMessage "Configuration file is missing 'Destination' property."
}

if (-not ($config | Get-Member -MemberType NoteProperty -Name "FilesToBackup")) {
    Handle-Error -ErrorMessage "Configuration file is missing 'FilesToBackup' property."
}

if (-not ($config.FilesToBackup -is [array])) {
    Handle-Error -ErrorMessage "'FilesToBackup' property in the configuration file must be an array."
}

foreach ($item in $config.FilesToBackup) {
    if (-not ($item | Get-Member -MemberType NoteProperty -Name "Source" -ErrorAction SilentlyContinue)) {
        Handle-Error -ErrorMessage "Each item in 'FilesToBackup' must have a 'Source' property."
    }

    if (-not ($item | Get-Member -MemberType NoteProperty -Name "Destination" -ErrorAction SilentlyContinue)) {
        Handle-Error -ErrorMessage "Each item in 'FilesToBackup' must have a 'Destination' property."
    }
}

# Destination backup location
$backupLocation = $BackupLocation

# Check if the backup location exists, create if not
if (-not (Test-Path -Path $backupLocation -ErrorAction SilentlyContinue)) {
    try {
        New-Item -ItemType Directory -Path $backupLocation -Force -ErrorAction Stop | Out-Null
        Write-Log -Message "Created backup directory: $backupLocation"
    } catch {
        Handle-Error -ErrorMessage "Failed to create backup directory: $_"
    }
}

# Check if the last backup file exists, create if not
$lastBackupPath = Join-Path -Path $backupLocation -ChildPath "last_backup.txt"
if (-not (Test-Path -Path $lastBackupPath -ErrorAction SilentlyContinue)) {
    try {
        New-Item -ItemType File -Path $lastBackupPath -ErrorAction Stop | Out-Null
        Write-Log -Message "Created last backup file: $lastBackupPath"
    } catch {
        Handle-Error -ErrorMessage "Failed to create last backup file: $_"
    }
}

# Get the last backup timestamp
try {
    $lastBackup = Get-Item -Path $lastBackupPath -ErrorAction Stop
} catch {
    Handle-Error -ErrorMessage "Failed to get last backup timestamp: $_"
}

# Function to perform backup
function PerformBackup {
    try {
        Write-Log -Message "Starting backup process"
        # Iterate through files/directories to backup
        foreach ($item in $config.FilesToBackup) {
            $source = $item.Source
            $destination = Join-Path -Path $backupLocation -ChildPath $item.Destination
            
            # Check if the item has been modified since the last backup
            if ((Get-Item $source -ErrorAction Stop).LastWriteTime -gt $lastBackup.LastWriteTime) {
                # Perform backup
                Copy-Item -Path $source -Destination $destination -Recurse -Force -ErrorAction Stop
                Write-Log -Message "Backed up: $source to $destination"
            }
        }
        
        # Update the last backup timestamp
        Get-Date | Out-File -FilePath $lastBackupPath -ErrorAction Stop
        Write-Log -Message "Backup process completed successfully"
    } catch {
        Handle-Error -ErrorMessage "Backup process failed: $_"
    }
}

# Perform backup
PerformBackup
