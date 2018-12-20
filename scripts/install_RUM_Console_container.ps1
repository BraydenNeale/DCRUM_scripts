Param(
    #Number between 1 and 4 matching the container number to install the CAS into.
    [Parameter(Mandatory=$true)][int]$Container_to_Install,
    [String]$PrimaryCIP=$null,
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag
)

. "<PATH_TO>\DCRUM_Library.ps1"

# Only allowing 4 containers per host
if ($Container_to_Install -lt 1 -or $Container_to_Install -gt 4) {
    Write-Host "Usage: install_RUM_Console_Container [1-4]" -ForegroundColor Red
    Exit
}

# Create variables mapping to the container we want to install.
$Containername = "$($env:COMPUTERNAME)C$($Container_to_Install)"
$ContainerIP = MapDCRUMHostnameToIpAddress $env:COMPUTERNAME $Container_to_Install

$envDCRUM = GetDCRUMEnvironment $envFlag

# Don't install into an existing container
if (ContainerExists $Containername) {
    Write-Host "Container $Containername already exists: Aborting" -ForegroundColor Red
    Exit
}

# Confirmation
$confirm = Read-Host "Installing $envDCRUM RUM Console to $Containername : $ContainerIP - Are you sure you want to continue (y/n) ? "
if ($confirm -ne 'y')
{
    Write-Host "$Containername : Install aborted by user"
    Exit
}

# Calculate Host IP
$HostIP = MapDCRUMHostnameToIpAddress $env:COMPUTERNAME 0

CreateContainer $Containername $ContainerIP
InstallRUMConsoleIntoContainer $Containername $HostIP $envDCRUM

# Verify the RUM Console was succesfully installed
if (ContainerExists $Containername) {
    Write-Host "RUM Console install $Containername : $ContainerIP - Completed successfully" -ForegroundColor Green
} else {
    Write-Host "Error installing RUM Console $Containername : $ContainerIP" -ForegroundColor Red
}
