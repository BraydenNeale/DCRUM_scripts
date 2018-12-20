Param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

# import library functions
. "<PATH_TO>DCRUM_Library.ps1"

$envDCRUM = GetDCRUMEnvironment $envFlag
$CASServers = GetCasServers $envDCRUM

$masterconfiglocation = "<PATH>\cas_config\dashboard-custom.properties"
$mastericonslocation = "<PATH>\DCRUM\cas_config\custom"

Write-Output "DCRUM Featured Dashboard Icons sync script - written by Luke Boyling`n"

foreach ($CASServer in $CASServers)
{
    Write-Output "Copying new icons to $CASName"
	#Copy icons from master icons folder to CAS
	$CASHost = $CASServer.Host

    #Get destination paths, depending on if the CAS is inside a container or not
    if($CASServer.Container -ne $null)
    {
        $CASName = "$($CASServer.Host)$($CASServer.Container)"
        $DestinationConfigPath = "\\$CASHost\D$\containers\$CASName\Program Files\Dynatrace\CAS\config\dashboard-custom.properties"
        $DestinationIconPath = "\\$CASHost\D$\containers\$CASName\Program Files\Dynatrace\CAS\wwwroot\img\speedDial"
    }
    else
    {
        $CASName = "$($CASServer.Host)"
        $DestinationConfigPath = "\\$CASHost\D$\Program Files\Dynatrace\CAS\config\dashboard-custom.properties"
        $DestinationIconPath = "\\$CASHost\D$\Program Files\Dynatrace\CAS\wwwroot\img\speedDial"
    }
    Write-Output $DestinationConfigPath
    Write-Output $DestinationIconPath
	Copy-Item -Path $mastericonslocation -Destination $DestinationIconPath -Recurse -Force

    Write-Output "Copying dashboard-custom.properties to $CASName config folder"
    
    Copy-Item -Path $masterconfiglocation -Destination $DestinationConfigPath -Force    
    Write-Output "Copy to $CASName complete"    
}
Write-Output "Copy complete for all listed CAS servers"