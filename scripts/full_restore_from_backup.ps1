param(
    [Parameter(Mandatory=$true, HelpMessage="The backup directory to restore from")][String]$backupDir
)

. "<PATH_TO>\DCRUM_Library.ps1"

Write-Host "A Full restore to the backup state in '$backupDir' will be Applied"
Write-Host "WARNING - This is a FULL restore: The current CAS config will be wiped" -ForegroundColor Yellow
Write-Host "Ensure the backup contains a COMPLETE backup of config - otherwise use partial_restore_from_backup_script.ps1"
ConfirmProcede "Are you sure you want to continue? "

$timeFile = "<PATH>\$($envDCRUM)_SP4_$(get-date -f yyyy-MM-dd_HH-mm).txt"
$summary = LogMessage "Restore Script started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
RestoreFromBackup $backupDir $false

if ($?) {
    Write-Host "Restore from backup - no errors detected" -ForegroundColor Green
} else {
    Write-Host "Errors occurred restoring from this backup file" -ForegroundColor Red
}

$summary = LogMessage "Restore Script finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
$summary | out-file $timeFile