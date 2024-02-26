# PowerShell Backup Script

This script automates the process of backing up specific files and directories to a designated backup location. It checks for modifications since the last backup and only backs up updated items.

## Prerequisites

- PowerShell 5.1 or later
- Administrator privileges

## Configuration

The script requires a configuration file named `backup_config.json` in the same directory as the script. The configuration file should contain the following JSON structure: 

```json
{
  "Destination": "C:\\Backups",
  "FilesToBackup": [
    {
      "Source": "C:\\Users\\Public\\Documents",
      "Destination": "Documents"
    },
    {
      "Source": "C:\\Users\\Public\\Pictures",
      "Destination": "Pictures"
    }
  ]
}
```
_**Note:** Paths must contain a double backslash "\\\\" otherwise the location of the file or folder will not be recognised._

## Backup Configuration Format
The following contains details about the key elements required in the backup configuration file to ensure accurate and efficient automated backups.

- **Destination**: The path to the backup location.
- **FilesToBackup**: An array of objects, each representing a file or directory to be backed up. Each object should have the following properties:
  - **Source**: The path to the source file or directory.
  - **Destination**: The path to the destination file or directory within the backup location.


## Usage

To run the script, open a PowerShell console and navigate to the directory containing the script and configuration file. Then, execute the following command:

```powershell
.\BackupScript.ps1
```

## How it Works

The script begins by loading the configuration from the `backup_config.json` file. It then checks if the backup location exists and creates it if necessary. Next, it checks if a file named `last_backup.txt` exists in the backup location. This file stores the timestamp of the last backup. If the file does not exist, it is created.

The script then defines a function called `PerformBackup`. This function iterates through the files and directories specified in the configuration file. For each item, it checks if the item has been modified since the last backup by comparing the last write time of the item with the timestamp stored in `last_backup.txt`. If the item has been modified, it is copied to the backup location.

Finally, the script calls the `PerformBackup` function to perform the backup. After the backup is complete, it updates the timestamp in `last_backup.txt` to the current date and time.
