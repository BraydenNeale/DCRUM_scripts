param (
    [Switch]$y = $false, # Add -y to auto confirm all DB changes
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

# import library functions
. "<PATH_TO>\DCRUM_Library.ps1"

$archive = @()
$CASServers = @()
$table = 'UserProperties' # or RtmProps for advanced settings
$property = 'HTTP_SESSION_TIMEOUT'
$value = 481
$backupServer = '\\<BACKUP_SERVER>'
$backupDir = "$backupServer\D$\Backup\Database_updates"

$envDCRUM = GetDCRUMEnvironment $envFlag
$CASServers = GetCasServers $envDCRUM

if (!(Test-Path $backupDir)) {
    Write-Host "Backup directory: '$backupdir' IS NOT REACHABLE. exiting..." -ForegroundColor Red
    exit
}

foreach ($CAS in $CASServers) {
    $archive += UpdateCASDatabaseProperty $($CAS.Instance) $($CAS.DB) $table $property $value $(!$y)
}

# Archive / Backup
$filename = "$($envDCRUM)_HTTP_timeout_$(get-date -f yyyy-MM-dd-HH-mm)"
$archive | out-file "$backupDir\$filename"