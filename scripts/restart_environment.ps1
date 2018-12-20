param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

. "D:\Data\Gitlab\DCRUM\scripts\DCRUM_Library.ps1"

$envDCRUM = GetDCRUMEnvironment $envFlag
$Console = GetRUMConsole $envDCRUM
$CASServers = GetCasServers $envDCRUM
$ADSServers = getADSServers $envDCRUM

Write-Host "Restarting $envDCRUM" -ForegroundColor Green

<# 
# CUSTOM RESTART
$CASServers = GetCustomCAS
foreach ($CAS in $CASServers) {
    RestartServiceAsJob $CAS
}
Get-Job | Wait-Job
#>

RestartServiceAsJob $Console
Get-Job | Wait-Job

Write-Host "RUM Console restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### FAILOVER CAS ####
$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::FAILOVER)
foreach ($CAS in $upgradeCASList) {
    RestartServiceAsJob $CAS
}
Get-Job | Wait-Job
Write-Host "Failover CAS' restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### MASTER CAS #### 
$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::MASTER)
foreach ($CAS in $upgradeCASList) {
    RestartServiceAsJob $CAS
}
Get-Job | Wait-Job
Write-Host "Master CAS' restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### PRIMARY CAS ####
$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::PRIMARY)
foreach ($CAS in $upgradeCASList) {
    RestartServiceAsJob $CAS
}
Get-Job | Wait-Job
Write-Host "Primary CAS' restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

#### SECONDARY CAS ####
$upgradeCASList = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::NODE)
foreach ($CAS in $upgradeCASList) {
    RestartServiceAsJob $CAS
}
Get-Job | Wait-Job
Write-Host "Secondary CAS' restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

# ADS
foreach ($ADS in $ADSServers) {
    RestartServiceAsJob $ADS
}
Get-Job | Wait-Job
Write-Host "ADS' restarted" -ForegroundColor Green
ConfirmProcede "Perform healthchecks: Confirm continue (y/n)"

Write-Host "Env $envDCRUM has been restarted" -ForegroundColor Green