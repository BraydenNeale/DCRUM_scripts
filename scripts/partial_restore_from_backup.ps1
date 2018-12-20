param(
    [Parameter(Mandatory=$true, HelpMessage="The zip file to restore to")][String]$backupFile
)

# Import DCRUM Libary
. "<PATH_TO>\DCRUM_Library.ps1"

Write-Host "Partial restore to the backup contained in $backupFile"
Write-Host "This will copy over each file individually: For a Full restore use full_restore_from_backup.ps1"
$confirm = Read-Host "Are you sure you want to continue (y/n) ? "
if ($confirm -ne 'y') {
    Write-Host "Backup restore aborted by user"
    Exit
}

$tempDir = "<TEMP_DIR_PATH>"

RestoreFromBackup $backupFile $tempDir $true

if ($?) {
    Write-Host "Restore from backup - no errors detected" -ForegroundColor Green
} else {
    Write-Host "Errors occurred restoring from this backup file" -ForegroundColor Red
}