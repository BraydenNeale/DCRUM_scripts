Param(
    #Number between 1 and 4 matching the container number to install the CAS into.
    [Parameter(Mandatory=$true)][Int]$Container_to_Install,
    [String]$PrimaryCIP=$null,
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String] $envFlag
)

. "<PATH_TO>\DCRUM_Library.ps1"

# Only allowing 4 containers per host
if ($Container_to_Install -lt 1 -or $Container_to_Install -gt 4) {
    Write-Host "Usage: install_CAS_Container [1-4]" -ForegroundColor Red
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

# Set required CAS member in HazelCast to be itself (unless otherwise specified)
if ($PrimaryCIP -eq $null) {
    $PrimaryCIP = $ContainerIP
}

# Confirmation
$confirm = Read-Host "Installing $envDCRUM CAS to $Containername : $ContainerIP - Are you sure you want to continue (y/n) ? "
if ($confirm -ne 'y')
{
    Write-Host "$Containername : Install aborted by user"
    Exit
}

# Calculate Host IP
$HostIP = MapDCRUMHostnameToIpAddress $env:COMPUTERNAME 0

CreateContainer $Containername $ContainerIP
InstallCASIntoContainer $Containername $ContainerIP $HostIP $PrimaryCIP $envDCRUM

# Verify the CAS was succesfully installed
if ((ContainerExists $Containername) -And (ValidWebResponseStatus "http://$ContainerIP")) {
        Write-Host "CAS install $Containername : $ContainerIP - Completed successfully" -ForegroundColor Green
} else {
    Write-Host "Error installing CAS $Containername : $ContainerIP" -ForegroundColor Red
}