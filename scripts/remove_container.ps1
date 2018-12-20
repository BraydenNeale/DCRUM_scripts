Param(
    [Parameter(Mandatory=$true)] 
    [int]$Container_to_Drop
)

. "<PATH>/DCRUM_Library.ps1"

$Containername = "$($env:COMPUTERNAME)C$($Container_To_Drop)"

# Check if we have already removed this container
if (!(ContainerExists $Containername)) {
    Write-Host "Container $Containername does NOT exist: Nothing to do" -ForegroundColor Yellow
    Exit
}
	
$warningtitle = "Deleting $Containername - confirmation"
$warningprompt = "You have selected to delete $Containername. Are you sure you want to delete this container?"

$no = New-Object System.Management.Automation.Host.ChoiceDescription '&No, do not delete', "No, I do not want to delete $Containername"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes, do delete', "Yes, I am sure that I want to delete $Containername"
$options = [System.Management.Automation.Host.ChoiceDescription[]] ($no, $yes)

$choice = $host.UI.PromptForChoice($warningtitle, $warningprompt, $options, 0)

if($choice -eq 0)
{
    Write-Host "$Containername has NOT been removed : Action aborted by user." -ForegroundColor Yellow
    exit
}

RemoveContainer $Containername

# Verify the container was removed
if (ContainerExists $Containername) {
    Write-Host "Error removing $Containername" -ForegroundColor Red
} else {
    Write-Host "$Containername : Succesfully removed" -ForegroundColor Green
}
