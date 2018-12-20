function Build-Script([String]$whitelist, [String]$blacklist) {
#TODO - only call this function on the 'all reports' page/tab
    return "

// **** CUSTOM ****

function hide_sections() {
  var sections = document.getElementsByClassName('dashboardSection');
  var whitelist = $whitelist;
  var blacklist = $blacklist;
  blacklist = blacklist.filter(function(el) {
    return whitelist.indexOf(el) == -1;
  });

  Array.from(sections).forEach(function(section) {
    var name = section.getElementsByClassName('sectionName')[0].innerHTML;

    for (var i = 0, len = blacklist.length; i < len; ++i ) {
      if (name.indexOf(blacklist[i]) != -1) {
        section.style.display = 'none';
        break;
      }
    }
  });
}
document.addEventListener('DOMContentLoaded', hide_sections, false);

// **** /CUSTOM **** 
"

}

# Default list of all report sections to hide - JavaScript array
$blacklist = "['Citrix workflow', 'Custom reports by', 'Combined EUE', 'Trace trimmer']"

$primaries = @()

# Whitelist is the list of report sections (contained within $blacklist) that you still want to show on that cluster
# Write it out like a JavaScript array - "['name1', 'name2']"

$primaries += @{Host="host1"; Whitelist="['Combined EUE']"}
$primaries += @{Host="host2"; Whiltelist="['Custom reports by']"}

$filename = 'login.js'
$filepath = "D$\Program Files\Dynatrace\CAS\wwwroot\script\$filename"
$backupHost = "BACKUP_HOSTNAME"
$backupDir = "\\$backupHost\D$\Data\ConfigBackup\CAS_JavaScript"

foreach ($CAS in $primaries) {
    # Dynatrace DCRUM JS gets bundled together on startup. To ensure custom JS persists you need to add it to a main JS file e.g. login.js and wait/restart
    # For instant testing you can use the file bundle\bundle_Core.js - but know that it won't persist
    # TODO - Custom JS file and edit the bundle scripts to pull that in

    $JSFile = "\\$($CAS.Host)\$filepath"

    if (!(Test-Path $JSFile)) {
        Write-Host "The file '$JSFile' does not exist... skipping this CAS" -ForegroundColor Yellow
        continue
    }

    # Get content of the existing file
    $backupContent = Get-Content -path $JSFile

    # Check we haven't already added this to the file
    if ($backupContent -match [regex]::Escape("**** CUSTOM ****")) {
        Write-Host "Custom JS has already been written to $JSFile... skipping this CAS" -ForegroundColor Yellow
    } else {
        $scriptContent = Build-Script $CAS.Whitelist $blacklist

        # Backup the old file
        $backupFile = "$($CASName)_$($filename)"
        $backupPath = "$backupDir\$backupFile"
        Set-Content -Path $backupPath -Value $backupContent

        # append script tag
        Add-Content -Path $($JSFile) -Value "$scriptContent"
        Write-Host "Custom JS written to $JSFILE" -ForegroundColor Green
    }
} 
