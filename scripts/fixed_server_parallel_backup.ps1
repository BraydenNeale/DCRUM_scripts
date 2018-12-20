param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

. "<PATH_TO>\DCRUM_Library.ps1"

# Quick Hack... could make more general but need a type property on the component object
function FullCASBackupsAsJob($group, [String]$backupServer, [String]$localBackupPath) {
    $backupDir = "\\$backupServer\$localBackupPath"
    
    # Doesn't work... DOUBLE HOP problem. Can't copy from a different server from a remote session
    #Invoke-Command -ComputerName $backupServer -ArgumentList ($group, $backupDir) -ScriptBlock {
	# So start the job using multiple threads from the central server
    Start-Job -ArgumentList ($group, $backupDir) -ScriptBlock {
        param($group, $backupDir)

        foreach ($CAS in $group) {
            $CASName = "$($CAS.Host)$($CAS.Container)"
            $CASBackupDir = "$backupDir\$CASName"

            #### CONFIG BACKUP ####
            $folderName = "CAS"
            $backupFile = "$CASBackupDir\$folderName"

            $CASPath = $null
            if([String]::IsNullOrWhiteSpace($CAS.Container)) {
                # Physical
                $CASPath = "\\$($CAS.Host)\D$\Program Files\Dynatrace"
            } else {
                # Container
                $CASPath = "\\$($CAS.Host)\D$\containers\$CASName\Program Files\Dynatrace"
            }

            $configFolder = "$CASPath\$folderName"

            New-Item -ItemType Directory -Force -Path $CASBackupDir
            if (!(Test-Path $CASBackupDir)) {
                Write-Host "Unable to reach the backup Directory '$CASBackupDir'" -ForegroundColor Red
                exit
            }

            Copy-Item -Path $configFolder -Destination $backupFile -Recurse -Force

            #### SQL Backup ####
            $backupFile = "$CASBackupDir\$($CAS.DB).bak"
            $tmpDir = "\\$($CAS.Host)\D$\tmp"
            New-Item -ErrorAction Ignore -ItemType directory -Path $tmpDir
            $localTempBackup = "$tmpDir\$($CAS.DB).bak"
            Backup-SqlDatabase -ServerInstance $CAS.Instance -Database $CAS.DB -BackupFile $localTempBackup -CompressionOption On
            Copy-Item -Path $localTempBackup -Destination $backupFile -Force
            Remove-Item -Path $localTempBackup -Force
        }
    } #-AsJob
}

$envDCRUM = GetDCRUMEnvironment $envFlag
$Console = GetRUMConsole $envDCRUM
$CASServers = GetCasServers $envDCRUM

$BACKUPNAME = "$($envDCRUM)_Full_Backup_$(get-date -f yyyy-MM-dd_HH-mm)"
$localBackupPath = "D$\Backup\Upgrade\$BACKUPNAME"
$BACKUPSERVERS = @()
# e.g.
$BACKUPSERVERS += "<BACKUP_SERVER>"
for ($i = 1; $i -le 50; $i++) {
    $BACKUPSERVERS += "<BACKUP_SERVER>$i"
}
$timeFile = "<PATH>\$($envDCRUM)_backup_$(get-date -f yyyy-MM-dd_HH-mm).txt"
$summary = LogMessage "Backup started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$chunkSize = [Math]::Ceiling($CASServers.Length / $BACKUPSERVERS.Length)
$groups = for ($i = 0; $i -lt $CASServers.length; $i += $chunkSize){ 
    ,($CASServers[$i..($i + ($chunkSize -1))])
}
$summary += LogMessage "Parallel CAS Backup started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$count = 0
$backupIdx = 0
foreach ($group in $groups) {
    $backupServer = $BACKUPSERVERS[$backupIdx++]
    $count += $group.Length
    $summary += LogMessage "Backing up CAS group $backupIdx to $backupServer started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
    FullCASBackupsAsJob $group $backupServer $localBackupPath
}
Get-Job | Wait-Job

$summary += LogMessage "Parallel CAS Backup finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
# BACKUP RUM CONSOLE Seperately
$summary += LogMessage "RUM Console Backup started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
# TODO: Type property in each component object so that RUM Console (and ADS) is nicely included in the groups 
Write-Host "Backing up RUM Console" -ForegroundColor Green
$backupDir = "\\<BACKUP_SERVER>\$localBackupPath"
FullComponentBackup $Console $backupDir ([ComponentDCRUM]::RUMCONSOLE)
$count += 1

$summary += LogMessage "RUM Console Backup finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$summary += LogMessage "`Backup servers = $($BACKUPSERVERS.Length)"
$summary += LogMessage "Chunksize = $chunkSize"
$summary += LogMessage "# Groups = $($groups.Length)"
$summary += LogMessage "# Components = $($CASServers.Length + 1)" # +1 for RUM Console
$summary += LogMessage "# Backed up = $count"

$summary += LogMessage "Backup finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
$summary | out-file $timeFile