param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

. "<PATH_TO>\DCRUM_Library.ps1"


$envDCRUM = GetDCRUMEnvironment $envFlag
$Console = GetRUMConsole $envDCRUM
$CASServers = GetCasServers $envDCRUM
$ADSServers = getADSServers $envDCRUM

$count = 0;
$total = 0;

$list = $null

# RUM CONSOLE
$list += "`nRUM Console`n"
$list += "$($Console.Host)$($Console.Container)`n"
$count++
$list += "# Console = $count`n"
$total += $count
$console_count = $count
$count = 0


# Failover CAS
$list += "`nFailover CAS`n"
$filtered = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::FAILOVER)
foreach ($CAS in $filtered) {
    $list += "$($CAS.Host)$($CAS.Container)`n"
    $count++
}
$list += "# Failover = $count`n"
$total += $count
$failover_count = $count
$count = 0

# Master CAS
$list += "`nMaster CAS`n"
$filtered = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::MASTER)
foreach ($CAS in $filtered) {
    $list += "$($CAS.Host)$($CAS.Container)`n"
    $count++
}
$list += "# Master = $count`n"
$total += $count
$master_count = $count
$count = 0

# Primary CAS
$list += "`nPrimary CAS`n"
$filtered = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::PRIMARY)
foreach ($CAS in $filtered) {
    $list += "$($CAS.Host)$($CAS.Container)`n"
    $count++
}
$list += "# Primary = $count`n"
$total += $count
$primary_count = $count
$count = 0

# Secondary CAS
$list += "`nSecondary CAS`n"
$filtered = FilterCASServers -CASServers $CASServers -Filter ([CASFilterOptions]::NODE)
foreach ($CAS in $filtered) {
    $list += "$($CAS.Host)$($CAS.Container)`n"
    $count++
}
$list += "# Secondary = $count`n"
$total += $count
$secondary_count = $count
$count = 0

$list += "`nADS`n"
foreach ($ADS in $ADSServers) {
    $list += "$($ADS.Host)$($ADS.Container)'n"
    $count++
}
$list += "`n# ADS = $count`n"
$total += $count
$ads_count = $count
$count = 0

$list += "`n# RUM Console = $console_count`n"
$list += "# Master CAS = $master_count`n"
$list += "# Primary CAS = $primary_count`n"
$list += "# Secondary CAS = $secondary_count`n"
$list += "# Failover CAS = $failover_count`n"
$list += "# ADS = $ads_count`n"
$list += "`n# Total components = $total`n"

Write-Host $list
$list | out-file "<PATH>$($envDCRUM)_Components_$(get-date -f yyyy-MM-dd_HH-mm).txt" -Force