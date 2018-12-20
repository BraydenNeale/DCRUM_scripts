param(
    [Parameter(Mandatory=$true, HelpMessage="The DCRUM environment to target - 'prod', 'preprod' or dev")][String]$envFlag,
    [Int]$ServicePackVersion=2,
    [Switch]$auto=$false
)

# import library functions
. "<PATH_TO>\DCRUM_Library.ps1"

Write-Output "DCRUM CAS Patching Scr!ipt - written by Luke Boyling`n"

#Copy listed patches to customQueries folder if not already existing.
#Edit classloader.properties
#Schedule restart.

$envDCRUM = GetDCRUMEnvironment $envFlag
$CASServers = GetCASServers $envDCRUM

#
# ****************************
# Patch list
# ****************************
#
#Provide paths to master copy of patch jars. Each patch has two parameters:
# Enabled: Whether the patch should actually be loaded by the CAS or just copied to the folder but disabled.
# Path: The full path to the location of the .jar file.

# IMPORTANT: If replacing a patch with a different file, don't delete the line. Just set Enabled to $false, and wait for the next restart to happen.
# After the reboot, the CAS shouldn't lock the jar file (which it does if there's a JAR it's not aware of).

$defaultPatchPath = "<PATH>\DCRUM\cas_config\patches"

$Patches = @()
<#
if ($ServicePackVersion -le 2) {
    $Patches += @{Enabled=$true; Path="$defaultPatchPath\<PATCH>.jar"}
}#>

if ($ServicePackVersion -le 4) {
    # For change 18/04/2018
    $Patches += @{Enabled=$True; Path="$defaultPatchPath\<PATH>.jar"}
}

#
# ****************************
# Script
# ****************************
#

# If we call this script from an install or upgrade - we dont want to be prompted and will have already backed up
if (!$auto) {
    Write-Output "The following patches will be applied:"
    $Patches| % {new-object PSObject -Property $_}| Format-Table -Autosize
    Write-Output "`nThe following CAS servers will be patched:"
    $CASServers | % {new-object PSObject -Property $_}| Format-Table -Autosize

    Write-Output "Backing up current patch folder contents for all servers to be patched."

    $backupfolder = mkdir "<BACKUP_PATH>\$($envDCRUM)_patch_$(get-date -f yyyy-MM-dd-HH-mm)"
    foreach ($CASServer in $CASServers)
    {
        $CASHost = $CASServer.Host
        $DestinationPath = ""
        $CASName = ""
        if($CASServer.Container -ne $null)
        {
            $CASName = $CASServer.Host + $CASServer.Container
            $DestinationPath = "\\$CASHost\D$\containers\$CASName\Program Files\Dynatrace\CAS\classes\customQueries"
        }
        else
        {
            $CASName = $CASServer.Host
            $DestinationPath = "\\$CASHost\D$\Program Files\Dynatrace\CAS\classes\customQueries"
        }

        #Backup existing patch config in case we need to revert the changes.
        Write-Output "Copying patches from $CASName - $DestinationPath"
    
        $casbackup = mkdir "$($backupfolder.FullName)\$CASName"
        Copy-Item "$DestinationPath\*" $CASbackup.FullName
        
    }
    Write-Output "Compressing patches into a .zip file..."
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($backupfolder, "$($backupfolder.FullName).zip")

    Remove-Item -Path $backupfolder -Recurse -Force

    Write-Output "Patches backed up to $backupfolder.zip"

    $Continue = Read-Host -Prompt "The script has backed up the patches to $backupfolder.zip. Do you wish to continue with the patching process (y/n)?"

    if($Continue -ne 'y')
    {
        Write-Output "Patching process has been cancelled. This script will now exit..."
        exit
    }
}

$classLoaderContents = @("# order of loading classes from JAR files")
$i = 0;
foreach ($patch in $patches)
{
    $i++
    if($patch.Enabled)
    {
        $classLoaderContents += "$i=$(Split-Path $patch.Path -Leaf)"
    }
    else
    {
        $classLoaderContents += "$i=#$(Split-Path $patch.Path -Leaf)"
    }
}
$classLoaderContents += ""

$classLoaderBackupPath = "<BACKUP_PATH>\Backup\Patches\"

if (!(Test-Path "$classLoaderBackupPath\classLoader.properties"))
{
    Write-Output "File does not exist, creating"
    New-Item -path $classLoaderBackupPath -Name "classLoader.properties" -Type File -Value ""
}
Out-String -Stream | &{[String]::Join("`n", $classLoaderContents)} | out-File -filePath "$classLoaderBackupPath\classLoader.properties" -encoding utf8

foreach ($CASServer in $CASServers)
{
    $CASHost = $CASServer.Host
    $CASName = "$($CASServer.Host)$($CASServer.Container)"

    
    if($CASServer.Container -ne $null)
    {
        $DestinationPath = "\\$CASHost\D$\containers\$CASName\Program Files\Dynatrace\CAS\classes\customQueries"
    }
    else
    {        
        $DestinationPath = "\\$CASHost\D$\Program Files\Dynatrace\CAS\classes\customQueries"
    }
    Write-Output "Copying new patches to $CASName"
    
    foreach ($patch in $patches)
    {
            Copy-Item $patch.Path $DestinationPath -Force
    }
    Copy-Item "$classLoaderBackupPath\classLoader.properties" $DestinationPath
}

rm "$classLoaderBackupPath\classLoader.properties"