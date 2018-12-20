param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag,
    [Switch]$auto=$false
)

# import library functions
#. "<PATH_TO>/DCRUM_Library.ps1"
. "<PATH_TO>\DCRUM_Library.ps1"

$archive = @()
$envDCRUM = GetDCRUMEnvironment $envFlag
$CASServers = GetCasServers $envDCRUM

$backupFile = "$($envDCRUM)_Offset_tasks-100_$(get-date -f yyyy-MM-dd-HH-mm)"
$oldOffset = "offsetTime=""00:30"""
$backupDir = "D:\Backup\Config"
$tmpDir = "D:\tmp\$backupFile"
$filename = "tasks-100-hcbs.xml"


# Every task has it's own start time... we only want to change TableDailyTask
$oldValue = "<task ID=""TableDailyTask"" name=""Updates statistics on tables, removes old data on periodical tables"" periodType=""DAY"" period=""1"" timeLine=""SERVER"" $oldOffset timeout=""01:00"" recoverable=""true"">"

# Don't prompt and backup if running via auto - e.g. SP4 upgrade
if (!$auto) {
    $confirm = Read-Host "Updating value = '$oldOffset' - file = '$filename' in $envDCRUM : Are you sure you want to continue (y/n) ? "
    if ($confirm -ne 'y') {
        Write-Host "Aborted by user"
        Exit
    }

    New-Item -ItemType Directory -Force -Path $tmpDir
    if(!$?) {
        Write-Host "Could not create backup Directory '$tmpDir' ABORTING" -ForegroundColor Red
        exit
    }

    foreach ($CAS in $CASServers) {
        $filePath = "$(GetDynatraceComponentPath $CAS.Host $CAS.Container)\CAS\config\$filename"
        BackupConfigFile $CAS $filePath $tmpDir ([ComponentDCRUM]::CAS)
    }

    CompressZipArchive $tmpDir $backupDir

    if (!(Test-Path "$backupDir\$backupFile.zip")) {
        Write-Host "Error Backing up CAS configuration: Aborting" -ForegroundColor Red
        exit
    }

    Write-Host "CAS Configuration has been backed up to $backupDir\$backupFile.zip" -ForegroundColor Green
}

# LETS SET THE START TIME TO THE HOST NUMBER... SHOULD BE FAIRLY EVEN
foreach ($CAS in $CASServers) {
    $min = $CAS.Host[-1]
    # Confirm it's a single digit number
    if (!($min -match '^[0-9]$')) {
        $archive += "`n$($CAS.Host)$($CAS.Container) - Not updated - Hostname doesn't end with a digit?"
        continue
    }

    $newOffset = "offsetTime=""00:3$min"""
    $newValue = $oldValue.replace($oldOffset, $newOffset)

    $filePath = "$(GetDynatraceComponentPath $CAS.Host $CAS.Container)\CAS\config\$filename"

    $archive += UpdateFileValue $filePath $oldOffset $newOffset
}

Write-Host "$archive"