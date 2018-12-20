param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

. "<PATH_TO>\DCRUM_Library.ps1"

$envDCRUM = GetDCRUMEnvironment $envFlag
$Console = GetRUMConsole $envDCRUM
$CASServers = GetCasServers $envDCRUM
$ADSServers = getADSServers $envDCRUM

$CASBuildNumber = 18.0195
$RUMConsoleBuildNumber = 18.012551

#### Confirmation ####
Write-Host "RUM Console: $($Console.Host)$($Console.Container)"
foreach ($CAS in $CASServers) {
    Write-Host "CAS: $($CAS.Host)$($CAS.Container)"
}
foreach ($ADS in $ADSServers) {
    Write-Host "ADS: $($ADS.Host)$($ADS.Container)"
}

Write-Host "Service pack upgrade will be applied to $envDCRUM - The services listed above will be upgraded."
ConfirmProcede "Are you sure you want to continue (y/n) ? "

$timeFile = "<PATH>\$($envDCRUM)_SP4_$(get-date -f yyyy-MM-dd_HH-mm).txt"
$summary = LogMessage "Script started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

#### UPGRADE ####

# Apply service pack upgrade in place
# Upgrade order:
# - Rum Console
# - Failover
# - CAS - Primary Node - Primary Cluster (Master)
# - CAS primary nodes
# - CAS secondary nodes
# - ADS

#### RUM CONSOLE ####
$summary += LogMessage "`RUM Console upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)" 
#UpgradeRUMConsole $Console $RUMConsoleBuildNumber
$summary += LogMessage "`RUM Console upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### FAILOVER CAS ####
$summary += LogMessage "Failover CAS upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::FAILOVER)
foreach ($CAS in $upgradeCASList) {
    UpgradeCAS $CAS $CASBuildNumber
}
Get-Job | Wait-Job
foreach ($CAS in $upgradeCASList) {
    StartServiceAndTasks $CAS
}

$summary += LogMessage "Failover CAS upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### MASTER CAS ####
$summary += LogMessage "Master CAS upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)" 

$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::MASTER)
foreach ($CAS in $upgradeCASList) {
    UpgradeCAS $CAS $CASBuildNumber
}
Get-Job | Wait-Job
foreach ($CAS in $upgradeCASList) {
    StartServiceAndTasks $CAS
}

$summary += LogMessage "Master CAS upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### PRIMARY CAS ####
$summary += LogMessage "Primary CAS upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::PRIMARY)
foreach ($CAS in $upgradeCASList) {
    UpgradeCAS $CAS $CASBuildNumber
}
Get-Job | Wait-Job
foreach ($CAS in $upgradeCASList) {
    StartServiceAndTasks $CAS
}

$summary += LogMessage "Primary CAS upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### SECONDARY CAS ####
$summary += LogMessage "Secondary CAS upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"

$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::NODE)
foreach ($CAS in $upgradeCASList) {
    UpgradeCAS $CAS $CASBuildNumber
}
Get-Job | Wait-Job
foreach ($CAS in $upgradeCASList) {
    StartServiceAndTasks $CAS
}

$summary += LogMessage "Secondary CAS upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### ADS ####
$summary += LogMessage "ADS upgrade started at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
foreach ($ADS in $ADSServers) {
    UpgradeADS $ADS
}
Get-Job | Wait-Job
foreach ($ADS in $ADSServers) {
    StartServiceAndTasks $ADS
}

$summary += LogMessage $status = "ADS upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### /Upgrade ****

$summary += LogMessage "Upgrade finished at $(get-date -f yyyy-MM-dd_HH-mm-ss)"
$summary | out-file $timeFile