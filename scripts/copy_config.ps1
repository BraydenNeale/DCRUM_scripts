param (
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String] $envFlag,
    [Switch]$auto=$false
)

. "<PATH_TO>\DCRUM_Library.ps1"

$envDCRUM = GetDCRUMEnvironment $envFlag
$CASServers = GetCasServers $envDCRUM

$configSourceDir = "<PATH>\DCRUM\cas_config"
$configDir = "Program Files\Dynatrace\CAS\config"

$propertyFiles = @()
$propertyFiles += "reportTime-custom.properties"
$propertyFiles += "dashboard-custom.properties"
$propertyFiles += "locations-sample.config"

foreach ($CAS in $CASServers) 
{
    $CASName = "$($CAS.Host)$($CAS.Container)"
    foreach ($file in $propertyFiles) {
        $configDestPath = ""

        #Get destination paths, depending on if the CAS is inside a container or not
        if($CAS.Container -ne $null)
        {
            $configDestPath = "\\$($CAS.Host)\D$\containers\$CASName\$configDir\$file"
        }
        else
        {
            $configDestPath = "\\$($CAS.Host)\D$\$configDir\$file"
        }

        $configSourcePath = "$configSourceDir\$file"

        if (Test-Path $configSourcePath) {
            Copy-Item -Path $configSourcePath -Destination $configDestPath -Force

            #if the copy succeeded
            if ($?) {
                Write-Host "Config file '$file' copied to $CASName" -ForegroundColor Green
            } else {
                Write-Host "$configSourcePath, $configDestPath"
            }
        }
    }
    Write-Host ""
}