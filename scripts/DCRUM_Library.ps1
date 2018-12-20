<# **** DCRUM COMMON LIBRARY FUNCTIONS ****
    Import these functions into your own scripts with:
    . "<PATH_TO>\DCRUM_Library.ps1"
#>

##### TYPE DECLARATIONS #####

# COMPONENT OBJECT
# { Host, Container, Instance, DB }

Add-Type -TypeDefinition @"
    public enum EnvironmentDCRUM {
        DEV,
        PREPROD,
        PROD,
        SANDBOX
    }
"@

Add-Type -TypeDefinition @"
    public enum CASFilterOptions {
        PRIMARY,
        NODE,
        FAILOVER,
        MASTER,
        PHYSICAL,
        CONTAINER
    }
"@

Add-Type -TypeDefinition @"
    public enum ComponentDCRUM {
        CAS,
        ADS,
        RUMCONSOLE
    }
"@

# CONSTANTS
$PROD_API_TOKEN = '<PROD_API_TOKEN>'
$DEV_API_TOKEN = '<DEV_API_TOKEN>'
$PREPROD_API_TOKEN = '<PREPROD_API_TOKEN>'
$SANDBOX_API_TOKEN = '<SANDBOX_API_TOKEN>'

$PROD_RUM_CONSOLE_URL = 'https://<RUM_CONSOLE_PROD_URL>:4183'
$PREPROD_RUM_CONSOLE_URL = 'https://<RUM_CONSOLE_PREPROD_URL>:4183'
$DEV_RUM_CONSOLE_URL = 'https://<RUM_CONSOLE_DEV_URL>:4183'
$SANDBOX_RUM_CONSOLE_URL = 'https://<RUM_CONSOLE_SANDBOX_URL>:4183'

$SCRIPT_PATH = "<PATH>\DCRUM\scripts"

##### /TYPE DECLARATIONS #####

##### FUNCTION DEFINITIONS #####

<##### PUBLIC FUNCTION DEFINITIONS #####
    C# Naming Nonvention - MyFunction()

    ## CoreFunctions ##
    GetDCRUMEnvironment([String]$envFlag)
    GetComponentFromName([String]$componentName)
    MapComponentToFolder([ComponentDCRUM]$type)
    GetCasServers([EnvironmentDCRUM]$envDCRUM)
    GetRUMConsole([EnvironmentDCRUM]$envDCRUM)
    getADSServers([EnvironmentDCRUM]$envDCRUM)
    FilterCASServers($CASServers, [CASFilterOptions]$filter, [Bool]$negation=$false)
    UpdateCASDatabaseProperty([String]$instance, [String]$DBName, [String]$table, [String]$property, [int]$value, [Bool]$prompt=$true)
    MapDCRUMHostnameToIpAddress($Hostname, $Offset = 0)
    MapDCRUMHostnameToSubnetHost($Hostname, $Offset = 0)
    CreateContainer([String]$Containername, [String]$ContainerIP)
    InstallCASIntoContainer([String]$Containername, [String]$ContainerIP, [String]$HostIP, [String]$primraryCIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD)
    InstallADSIntoContainer([String]$Containername, [String]$ContainerIP, [String]$HostIP, [String]$primraryCIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD)
    InstallRUMConsoleIntoContainer([String]$Containername, [String]$HostIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD)
    RemoveContainer([String]$Containername)
    FullComponentBackup($Component, [String]$backupDir, [ComponentDCRUM]$type)
    FullS3Backup($Component, [String]$backupDir, [ComponentDCRUM]$type)
    BackupConfigFile($Component, [String]$filePath, [String]$backupDir, [ComponentDCRUM]$type)
    RestoreFromBackup([String]$backupDir, [Bool]$partial=$true)
    ScheduledTaskHandler($Component, [String]$taskName, [Bool]$enable)
    GetAllCASServers()
    GetAllADSServers()
    GetAllRUMConsoles()
    GetCustomCAS()
    UpgradeRUMConsole($Console, [Decimal]$BuildNumber=17.04215)
    UpgradeCAS($CAS)
    UpgradeADS($ADS)
    StartServiceAndTasks($Component)
    StopServiceAndTasks($Component)
    RestartServiceAsJob($Component)
    GetPhysicalServers()

    ## HelperFunctions ##
    TestDCRUMLibrary()
    UpdateFileValue([String]$filePath, [String]$oldValue, [String]$newValue)
    ContainerExists([String]$Containername)
    CompressZipArchive([String]$tempFolder, [String]$backupFolder=$null)
    GetDynatraceComponentPath([String]$hostname, [String]$container)
    InvokeRemoteCommand($Component, $remoteCommand)
    ValidWebResponseStatus([String]$URL)
    BackupComponentDatabase([String]$backupFile, [String]$localTempBackup, [String]$instance, [String]$DBName)
    RestoreComponentDatabase([String]$backupFile, [String]$localTempBackup, [String]$instance, [String]$DBName)
    AddLineToFile([String]$filename, [String]$after, [String]$content)
    ConfirmProcede([String]$message)
    StopDynatraceService($Component)
    StartDynatraceService($Component)

    ## Private Functions ##
    UpgradeComponent($Component, [ComponentDCRUM]$type, [Decimal]$BuildNumber=17.04215)
    GetPrimaryCasServers()
    GetPreprodCASServers()
    GetDevCASServers()
    GetProdCASServers()
    FilterPrimaryCAS($CASServers, [Bool]$negation=$false)
    FilterFailoverCAS($CASServers, [Bool]$negation=$false)
    FilterMasterCAS ($CASServers, [Bool]$negation=$false)
    FilterNodeCAS($CASServers, [Bool]$negation=$false)
    FilterPhysicalCAS($CASServers, [Bool]$negation=$false)
    FilterContainerCAS($CASServers, [Bool]$negation=$false)
    GetProdADSServers()
    GetPreprodADSServers()
    GetDevADSServers()
    GetDevRumConsole()
    GetPreprodRumConsole()
    GetProdRumConsole() 
    GetCasFromName([String]$CASName)
    GetADSFromName([String]$ADSName)
    GetRUMConsoleFromName([String]$consoleName)

##### /FUNCTION DEFINITIONS #####>

##### CORE FUNCTIONS #####

# Converts a string parameter into a DCRUM environment - DEV, PREPROD, SANDBOX or PROD
function GetDCRUMEnvironment([String]$envFlag) {
    $envDCRUM = $null

    switch ($envFlag) {
        dev {
            $envDCRUM = [EnvironmentDCRUM]::DEV
        }
        preprod {
           $envDCRUM = [EnvironmentDCRUM]::PREPROD 
        }
        prod {
            $envDCRUM = [EnvironmentDCRUM]::PROD
        }
        sandbox {
            $envDCRUM = [EnvironmentDCRUM]::SANDBOX
        }
        default {
            Write-Host "Invalid Environment flag detected : Usage dev | preprod | prod | sandbox" -ForegroundColor Red
            Exit
        }
    }

    return $envDCRUM
}

# Find a DCRUM Component Object matching a name string
function GetComponentFromName([String]$componentName) {
    # CAS?
    $Component = GetCasFromName $componentName
    if ($Component -eq $null -or $Component.Host -eq $null) {
        # RUM Console?
        $Component = GetRUMConsoleFromName $componentName

        if ($Component -eq $null -or $Component.Host -eq $null) {
            # ADS?
            $Component = GetADSFromName $componentName
        }
    }

    return $Component
}

# Get the name of the Component folder from the type of component
# Use with GetDynatraceComponentPath to get the full path of any component
function MapComponentToFolder([ComponentDCRUM]$type) {
    $folderName = ""

    switch ($type) {
        CAS {
            $folderName = "CAS"
        }
        ADS {
            $folderName = "ADS"
        }
        RUMCONSOLE {
            $folderName = "RUM Console"
        }
        default {
        }
    }

    return $folderName
}

# Return a lists of all the CAS in the specified environment: Host, Container, Instance, DB
# Usage: GetCasServers ([EnvironmentDCRUM]::PREPROD)
function GetCasServers([EnvironmentDCRUM]$envDCRUM) {
    $CASServers = @()

    switch ($envDCRUM) {
        PREPROD {
            $CASServers = GetPreprodCASServers
        }
        DEV {
            $CASServers = GetDevCASServers
        }
        PROD { 
            $CASServers = GetProdCASServers 
        }
        SANDBOX {
            $CASServers = GetSandboxCASServers
        }
        default {
            # Return empty list
        }
    }

    return $CASServers
}

# Return the RUM Console for the specified environment: Host, Container, Instance, DB
# Usage: GetRUMConsole ([EnvironmentDCRUM]::PREPROD)
function GetRUMConsole([EnvironmentDCRUM]$envDCRUM) {
    $Console = $null

    switch ($envDCRUM) {
        DEV {
            $Console = GetDevRumConsole
        }
        PREPROD {
            $Console = GetPreprodRumConsole
        }
        PROD {
            $Console = GetProdRumConsole
        }
        SANDBOX {
            $Console = GetSandboxRumConsole
        }
        default {
            # no console
        }
    }

    return $Console
}

# Return a list of ADS Servers for the specified environment: Host, Container, Instance, DB
# Usage: getADSServers ([EnvironmentDCRUM]::PREPROD)
function getADSServers([EnvironmentDCRUM]$envDCRUM) {
    $ADSServers = @()

    switch ($envDCRUM) {
        PREPROD {
            $ADSServers = GetPreprodADSServers
        }
        DEV {
            $ADSServers = GetDevADSServers
        }
        PROD { 
            $ADSServers = GetProdADSServers
        }
        SANBDOX { 
            $ADSServers = GetSandboxADSServers
        }
        default {
            # Return empty list
        }
    }

    return $ADSServers
}

# Filter an exiting list of CAS servers (e.g. all of DEV) by CASFilterOptions
# e.g. all Dev Failovers or All Dev CAS' that aren't Primaries
function FilterCASServers($CASServers, [CASFilterOptions]$filter, [Bool]$negation=$false) {
    $filteredCASServers = $CASServers

    switch ($filter) {
        PRIMARY {
            $filteredCASServers = FilterPrimaryCAS $CASServers $negation
        }
        NODE {
            $filteredCASServers = FilterNodeCAS $CASServers $negation
        }
        FAILOVER {
            $filteredCASServers = FilterFailoverCAS $CASServers $negation
        }
        MASTER { 
            $filteredCASServers = FilterMasterCAS $CASServers $negation
        }
        PHYSICAL {
            $filteredCASServers = FilterPhysicalCAS $CASServers $negation
        }
        CONTAINER {
            $filteredCASServers = FilterContainerCAS $CASServers $negation
        }
        default {
            # No filter - return CASServers as it was passed in
        }
    }

    return $filteredCASServers
}

# Updates a Database property (CAS only for now... but could be more general)
# Returns a string of the outcome - for logging
function UpdateCASDatabaseProperty([String]$instance, [String]$DBName, [String]$table, [String]$property, [int]$value, [Bool]$prompt=$true) {
    import-module sqlps
    
    # TODO - handle cases where property to change is a string

    # Check DB connectivity by querying for a property that always exists
    $dataSet = Invoke-Sqlcmd -ServerInstance $instance -Database $DBName -Query "SELECT PropertyValue FROM [delta].[UserProperties] Where PropertyName=N'bulk.read' AND userName=N'SYSTEM'"

    $message = ""
    if ($dataSet -eq $null) {
        $message = "$DBName - $table - $property : SQL instance $instance - Database $DBName is unreachable"
        Write-Host $message -ForegroundColor Red
        return $message
    }
    
    # Check if property has already been set with a custom value
    $dataSet = Invoke-Sqlcmd -ServerInstance $instance -Database $DBName -Query "SELECT PropertyValue FROM [delta].[$table] Where PropertyName=N'$property' AND userName=N'SYSTEMCHANGED'"

    $priorproperty = $true
    if ($dataSet -eq $null) {
        $message = "$DBName - $table - $property : SQL instance $DBName - Property $property does not exist or has not been set to a custom value before"
        $priorproperty = $false
        #Write-Host $message -ForegroundColor Yellow
    }
	
    $backup = $dataSet.propertyValue

    if ($backup -eq $value) {
        $message = "$DBName - $table - $property : Value is already $value"
        Write-Host "$message" -ForegroundColor Yellow
        return $message
    } elseif ($backup -eq $null) {
        $message = "$DBName - $table - $property : No PropertyValue could be returned"
    }

    # PROMPT USER for confirmation
    if ($prompt) {
        if ($priorproperty -eq $true) {
			$confirm = Read-Host "Database $DBName : Updating property $property from $backup to $value - Are you sure you want to continue (y/n) ? "
		}
        else {
			$confirm = Read-Host "Database $DBName : Inserting new property $property with value $value - Are you sure you want to continue (y/n) ? "
        }


        if ($confirm -ne 'y') {
            $message = "$DBName - $table - $property : Update aborted by user"
            Write-Host "$message" -ForegroundColor Yellow
            return $message
        }
    }

    if ($priorproperty -eq $true) {
        # Update property
        Invoke-Sqlcmd -ServerInstance $instance -Database $DBName -Query "UPDATE [delta].[$table] SET PropertyValue = N'$value' WHERE PropertyName=N'$property' AND userName=N'SYSTEMCHANGED'"
        $message = "$DBname - $table - $property : Updated $backup -> $value"
        Write-Host "$message" -ForegroundColor Green
        return $message
    }
    else {
         # Insert new property
        Invoke-Sqlcmd -ServerInstance $instance -Database $DBName -Query "INSERT INTO [delta].[$table] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'$property' , N'$value' ) "
        $message = "$DBname - $table - $property : Inserted new value -> $value"
        Write-Host "$message" -ForegroundColor Green
        return $message
    }
}

# Hostname is the name of the DCRUM server
# offset is a value to add to the last octet (e.g. 1 for the First CAS). Default is 0
function MapDCRUMHostnameToIpAddress($Hostname, $Offset = 0)
{
	# CUSTOMER ENVIRONMENT SPECIFIC
	
	#e.g.
    $Octet1 = 127
    $Octet2 = 0
	$Octet3 = 0
	$Octet4 = 1

    #return concatenated IP address
    "$Octet1.$Octet2.$Octet3.$Octet4"
}

#Hostname is the name of the DCRUM server
#offset is a value to add to the last octet (e.g. 1 for the First CAS). Default is 0
function MapDCRUMHostnameToSubnetHost($Hostname, $Offset = 0)
{
	# CUSTOMER ENVIRONMENT SPECIFIC
	
	#e.g.
    $Octet1 = 127
    $Octet2 = 0
	$Octet3 = 0
	$Octet4 = 1

    #return concatenated IP address
    "$Octet1.$Octet2.$Octet3.$Octet4"
}

# Create a DCRUM report server container base from Windows server core and apply custom settings
# e.g. Combine with InstallCASIntoContainer to actually create and install a new CAS
function CreateContainer([String]$Containername, [String]$ContainerIP) {
    #create dirs
    New-Item B:\$Containername -type directory -Force
    New-Item D:\containers\$Containername -type directory -Force
    New-Item D:\containers\install -type directory -Force

    # create containers
	$dns = "127.0.0.1"
    docker run --name $Containername -h $Containername -d -i -v B:\$Containername\:c:\ram\ -v D:\containers\$Containername\:c:\soft\ -v d:\containers\install\:c:\install\ --network=TransparentNet --ip $ContainerIP --dns $dns microsoft/windowsservercore cmd
    
    docker exec $Containername cmd /c 'netsh int ipv4 add excludedportrange protocol=tcp startport=5700 numberofports=101 store=persistent'
    docker exec $Containername cmd /c 'netsh int ipv4 add excludedportrange protocol=tcp startport=1433 numberofports=1 store=persistent'

    # copy TCP registry changes
    Copy-Item "<path>\Scripts\net_tcp.reg" "d:\containers\install\net_tcp.reg"
}

# Install a new CAS into an existing Container: Specify the environment to set the URL and token for the RUM Console authentication
# TODO run through and apply all patching and config
function InstallCASIntoContainer([String]$Containername, [String]$ContainerIP, [String]$HostIP, [String]$primraryCIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD)
{
    Copy-Item "<PATH>\apm1704rumdc\CAS\*" "d:\containers\install\" -recurse -Force

    #create install answer files for each container
    Copy-Item "d:\containers\install\cas.properties" "d:\containers\install\$Containername.txt"

    #Replace SQL DB Name and SQL IP address in answer files for each container
    $properties = Get-Content "d:\containers\install\$Containername.txt"
    $properties = $properties.replace('SQL_SERVER_NAME_PANEL=localhost', "SQL_SERVER_NAME_PANEL=$HostIP").replace('SQL_DB_NAME=CAS', "SQL_DB_NAME=$Containername").replace('SQL_SERVER_NAME=localhost', "SQL_SERVER_NAME=$HostIP")

  # Set RUM Console host and API token depending on ENV - changed for dev and test
    switch ($env) {
        DEV {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$DEV_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$DEV_RUM_CONSOLE_URL")
        }
        PREPROD {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$PREPROD_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$PREPROD_RUM_CONSOLE_URL")
        }
        PROD {
            # API token as is
        }
        SANDBOX {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$SANDBOX_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$SANDBOX_RUM_CONSOLE_URL")
        }
        default {
            # Assumed prod
        }    
    }

    Set-Content "d:\containers\install\$Containername.txt" $properties

    #install within containers
    docker exec $Containername cmd /c "c:\install\CAS170_SP4_setupAMD64.exe -i silent -f $Containername.txt"
    docker exec $Containername cmd /c "regedit /s c:\install\CAS.reg"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\rtm-cv.properties").replace('zdata.GROUP_WITH=transdata,uemdata,gomezdata,ndata', "zdata.GROUP_WITH=uemdata,gomezdata,ndata") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\rtm-cv.properties"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\common-thread.properties").replace('DEFAULT_POOL_THREADS=500', "DEFAULT_POOL_THREADS=5000") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\common-thread.properties"
    docker exec $Containername cmd /c "regedit /s c:\install\net_tcp.reg"
    Invoke-Sqlcmd -Database $Containername -Query "UPDATE [delta].[RtmProps] SET PropertyValue = N'5000', BuildWhenUserChanged2 = 17000200094 WHERE PropertyName=N'RTM_JOB_RUN_FREQ'"
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.read' , N'b:\$Containername\' ) "
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.temp.file' , N'off' ) "
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.write' , N'c:\ram\' ) "
    docker exec -d $Containername cmd /c 'NET Start "WatchdogService"'

    # TODO increase threads

    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml").replace(' - bsmdata-Combined_EUE_RealTime_CVCache', "# - bsmdata-Combined_EUE_RealTime_CVCache") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml").replace(' - bsmdata-Combined_EUE_RealTime_TransView', "# - bsmdata-Combined_EUE_RealTime_TransView") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml").replace(' - Splunk_Analysis_by_Tier', "# - Splunk_Analysis_by_Tier") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\CAS\config\partner-export.yaml"

    # delete install content
    rm "d:\containers\install\*"
}

# Install a new ADS into an existing Container: Specify the environment to set the URL and token for the RUM Console authentication
# TODO run through and apply all patching and config
# TODO Update install to use SP4
function InstallADSIntoContainer([String]$Containername, [String]$ContainerIP, [String]$HostIP, [String]$primraryCIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD)
{
    Copy-Item "<PATH>\apm1702rumdc\Advanced Diagnostics Server\*" "d:\containers\install\" -recurse -Force
    
    Copy-Item "d:\containers\install\ads.properties" "d:\containers\install\$Containername.txt"

    #Replace SQL DB Name and SQL IP address in answer files for each container
    $properties = Get-Content "d:\containers\install\$Containername.txt"
    $properties = $properties.replace('SQL_SERVER_NAME_PANEL=localhost', "SQL_SERVER_NAME_PANEL=$HostIP").replace('SQL_DB_NAME=ADS', "SQL_DB_NAME=$Containername").replace('SQL_SERVER_NAME=localhost', "SQL_SERVER_NAME=$HostIP")

    # Set RUM Console host and API token depending on ENV - changed for dev and test
    switch ($env) {
        DEV {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$DEV_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$DEV_RUM_CONSOLE_URL")
        }
        PREPROD {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$PREPROD_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$PREPROD_RUM_CONSOLE_URL")
        }
        PROD {
            # API token as is
        }
        SANDBOX {
            $properties = $properties.replace("DCRUM_API_TOKEN=$PROD_API_TOKEN", "DCRUM_API_TOKEN=$SANDBOX_API_TOKEN").replace("CVA_URL=$PROD_RUM_CONSOLE_URL", "CVA_URL=$SANDBOX_RUM_CONSOLE_URL")
        }
        default {
            # Assumed prod
        }    
    }

    Set-Content "d:\containers\install\$Containername.txt" $properties

    #install within containers
    docker exec $Containername cmd /c "c:\install\ADS170_SP2_setupAMD64.exe -i silent -f $Containername.txt"
    docker exec $Containername cmd /c "regedit /s c:\install\ADS.reg"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\ADS\config\common-thread.properties").replace('DEFAULT_POOL_THREADS=500', "DEFAULT_POOL_THREADS=5000") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\ADS\config\common-thread.properties"
    docker exec $Containername cmd /c "regedit /s c:\install\net_tcp.reg"
    Invoke-Sqlcmd -Database $Containername -Query "UPDATE [delta].[RtmProps] SET PropertyValue = N'5000', BuildWhenUserChanged2 = 17000200094 WHERE PropertyName=N'RTM_JOB_RUN_FREQ'"
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.read' , N'b:\$Containername\' ) "
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.temp.file' , N'off' ) "
    Invoke-Sqlcmd -Database $Containername -Query "INSERT INTO [delta].[UserProperties] ( userName , propertyName , propertyValue )  VALUES ( N'SYSTEMCHANGED' , N'bulk.write' , N'c:\ram\' ) "
    docker exec -d $Containername cmd /c 'NET Start "WatchdogService"'

    # delete install content
    rm "d:\containers\install\*"
}

# Install a new RUM Console into a container
# TODO Automate LDAP config
function InstallRUMConsoleIntoContainer([String]$Containername, [String]$HostIP, [EnvironmentDCRUM]$env=[EnvironmentDCRUM]::PROD) {
    
    # Determine API key for the RUM Console - Preprod or Dev (Container RUM console for prod not yet? supported)
    $APIKey = $null

    switch ($env) {
        DEV {
            $APIKey = $DEV_API_TOKEN
         
        }
        PREPROD {
            $APIKey = $PREPROD_API_TOKEN
        }
        PROD {
            # null
            $APIKey = $PROD_API_TOKEN
        }
        SANDBOX {
            $APIKey = $SANDBOX_API_TOKEN
        }
        default {
            # null
        }
    }

    if ($APIKey -eq $null) {
        Write-Host "No APIKey for RUM Console - Aborting" -ForegroundColor Red
        Exit
    }

    # Copy RUM Console Setup.exe and answer file to local install folder.
    Copy-Item "<PATH>\apm1702rumdc\RUM Console\*" "d:\containers\install\" -recurse -Force

    #create install answer file for RUM Console
    Copy-Item "d:\containers\install\rumconsole.properties" "d:\containers\install\$Containername.txt"

    #Replace SQL DB Name and SQL IP address in answer files for each container
    # Choose RUM Console database name - use container name
    (Get-Content "d:\containers\install\$Containername.txt").replace('SQL_SERVER_NAME_PANEL=localhost', "SQL_SERVER_NAME_PANEL=$HostIP").replace('SQL_DB_NAME=Console_test', "SQL_DB_NAME=$Containername").replace('SQL_SERVER_NAME=localhost', "SQL_SERVER_NAME=$HostIP") | Set-Content "d:\containers\install\$Containername.txt"

    #install within container
    docker exec $Containername cmd /c "c:\install\install.exe -i silent -f $Containername.txt"
    
	# CUSTOMER ENVIRONMENT CONFIG - Very Large CAS deployment
    #Increase maximum database connections
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\database.properties").replace('database.connections.maxActive=200', "database.connections.maxActive=400") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\database.properties"

    #Increase threads
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\executors.properties").replace('serverThreadPoolExecutor.threads=50', "serverThreadPoolExecutor.threads=400") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\executors.properties"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\executors.properties").replace('scheduledExecutor.threads=60', "scheduledExecutor.threads=120") | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\executors.properties"

    #Increase length of time between when RUM Console checks health of all connected devices
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties").replace('job.get.health.repeatInterval=5', 'job.get.health.repeatInterval=30') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties"

    #Increase length of time between when RUM Console checks NFC health of all connected AMDs
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties").replace('job.get.data.nfc.repeatInterval=5', 'job.get.data.nfc.repeatInterval=30') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties"
    
    #Increase length of time between when RUM Console checks AppMon System Profiles of all connected devices
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties").replace('job.get.data.dt.repeatInterval=5', 'job.get.data.dt.repeatInterval=30') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties"
    
    #Increase length of time between when RUM Console checks Universal Decode status of all connected AMDs
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties").replace('job.get.data.universalDecode.repeatInterval=5', 'job.get.data.universalDecode.repeatInterval=30') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties"

    #Increase length of time between when RUM Console checks the type and installed version of all connected devices
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties").replace('job.get.typeversion.repeatInterval=5', 'job.get.typeversion.repeatInterval=30') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jobs.properties"

    #Decrease level of logging
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\logback.xml").replace('<logger name="com.dynatrace.console.security" level="DEBUG" />', '<logger name="com.dynatrace.console.security" level="DEBUG" />') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\logback.xml"
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\logback.xml").replace('</configuration>', '<logger name="com.compuware.configuration.jetty.server.AuthenticationHandler" level="ERROR" /></configuration>') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\logback.xml"
    
    #Increase max number of Jetty threads
    (Get-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jetty\etc\jetty.xml").replace('"threads.max" default="200"', '"threads.max" default="2000"') | Set-Content "d:\containers\$Containername\Program Files\Dynatrace\RUM Console\workspace\configuration\jetty\etc\jetty.xml"

    #Sets the API token for the RUM Console. This key needs be the same in the cas.properties and ads.properties answer files, so that the CAS and ADS get the same API token
    #INVALID OBJECT NAME? - HAVE TO SET THIS MANUALLY...
    Invoke-Sqlcmd -Database $Containername -Query "UPDATE [console].[API_TOKENS] SET JWT_TOKEN = N'$APIKey' WHERE ID=1"

    #Starts the RUM Console
    docker exec -d $Containername cmd /c 'NET Start "WatchdogService"'

    # delete install content
    rm "d:\containers\install\*"

}

# Completely uninstall a report server from a container (remove files and DB) and delete the container
function RemoveContainer([String]$Containername) {
    import-module sqlps

    # remove container
    Write-Host "Stopping container $Containername..."
    docker stop $Containername 

    Write-Host "Deleting container $Containername..."
    docker rm $Containername 
    Write-Host "Container $Containername deleted" -ForegroundColor Yellow

    # remove old files
    Write-Host "Removing D:\containers\$Containername folder..."
    rm D:\containers\$Containername -Recurse -Force
    Write-Host "D:\containers\$Containername deleted. Removing B:\$Containername folder..."
    rm B:\$Containername -Recurse
    Write-Host "B:\$Containername deleted"
    
    # remove SQL DBs
    Write-Host "Removing database $Containername..."
    invoke-sqlcmd -Query "Drop database $Containername;"
    Write-Host "Database $Containername removed" -ForegroundColor Yellow
}

# Fully backup a reporting server to the specified backup directory
# Backups are in the following format
    # Component name
        # Component type folder (e.g. RUM Console)
        # Component DB backup file
function FullComponentBackup($Component, [String]$backupDir, [ComponentDCRUM]$type) {
    $ComponentName = "$($Component.Host)$($Component.Container)"
    $ComponentBackupDir = "$backupDir\$ComponentName"

    # Backup Component Config
    $folderName = MapComponentToFolder $type
    $configFolder = "$(GetDynatraceComponentPath $Component.Host $Component.Container)\$folderName"
    $backupFile = "$ComponentBackupDir\$folderName"

    New-Item -ItemType Directory -Force -Path $ComponentBackupDir
    if (!(Test-Path $ComponentBackupDir)) {
        Write-Host "Unable to reach the backup Directory '$ComponentBackupDir'" -ForegroundColor Red
        exit
    }
    Copy-Item -Path $configFolder -Destination $backupFile -Recurse -Force
    
    # BACKUP SQL DATABASE
    $backupFile = "$ComponentBackupDir\$($Component.DB).bak"
    $localTempBackup = "\\$($Component.Host)\D$\tmp\$($Component.DB).bak"
    # Make sure there is actually a local tmp folder to write to
    New-Item -ErrorAction Ignore -ItemType directory -Path "\\$($Component.Host)\D$\tmp"

    BackupComponentDatabase $backupFile $localTempBackup $Component.Instance $Component.DB
}

# Fully backup a reporting server to S3 storage (AWS or MINIO)
# This runs each backup as a job/task so can be run in parallel
# Backups are in the following format
    # Component name
        # Component type folder (e.g. RUM Console)
        # Component DB backup file)
function FullS3Backup($Component, [String]$backupDir, [ComponentDCRUM]$type) {
    # Set environment vars for Minio
    $ComponentBackupDir = "$backupDir\$($Component.Host)$($Component.Container)"
    $folderName = MapComponentToFolder $type
    $configFolder = "$(GetDynatraceComponentPath $Component.Host $Component.Container)\$folderName"
    
    Invoke-Command -Computername $Component.Host -ArgumentList ($Component, $ComponentBackupDir, $folderName, $configFolder) -ScriptBlock {
        param($Component, $ComponentBackupDir, $folderName, $configFolder)

        # Backup Config
        $backupFile = "$ComponentBackupDir\$folderName"
        $minio_file_path = ("s3://$($env:MINIO_DCRUM_S3_BUCKET)/$backupFile" -replace '\\','/')
        aws --endpoint-url $($env:MINIO_ENDPOINT_URL) s3 cp $configFolder $minio_file_path --recursive #--no-progress --quiet

        # Backup SQL Database
        $backupFile = "$ComponentBackupDir\$($Component.DB).bak"
        New-Item -ErrorAction Ignore -ItemType directory -Path "\\$($Component.Host)\D$\tmp"
        $localTempBackup = "\\$($Component.Host)\D$\tmp\$($Component.DB).bak"
        Backup-SqlDatabase -ServerInstance $Component.Instance -Database $Component.DB -BackupFile $localTempBackup -CompressionOption On
        $minio_file_path = ("s3://$($env:MINIO_DCRUM_S3_BUCKET)/$backupFile" -replace '\\','/')
        aws --endpoint-url $($env:MINIO_ENDPOINT_URL) s3 cp $localTempBackup $minio_file_path #--no-progress --quiet

        Remove-Item -Path $localTempBackup -Force
    } -AsJob
}

# Backup a single file from a reporting server component
function BackupConfigFile($Component, [String]$filePath, [String]$backupDir, [ComponentDCRUM]$type) {
    $ComponentName = "$($Component.Host)$($Component.Container)"
    $folderName = MapComponentToFolder $type
    $ComponentBackupDir = "$backupDir\$ComponentName\$folderName"
    New-Item -ItemType Directory -Force -Path $ComponentBackupDir

    if (!(Test-Path $ComponentBackupDir)) {
        Write-Host "Unable to reach the backup Directory '$ComponentBackupDir'" -ForegroundColor Red
        exit
    }

    $relativePath = $filePath -split "\\$folderName\\" | select -last 1
    $backupPath = "$ComponentBackupDir\$relativePath"

    New-Item -ItemType Directory -Force -Path (Split-Path $backupPath)
    Copy-Item -Path $filePath -Destination $backupPath -Force
}

# Restore all reporting components that have been archived to a backup dir
# This walks the directory and restores all components files and databases
# Use the $partial flag to only backup individual files
# if partial is set to false the component directory will be removed and then backup will be copied over in bulk (TAKE CARE)
function RestoreFromBackup([String]$backupDir, [Bool]$partial=$true) {
    if (!(Test-Path $backupDir)) {
        Write-Host "Unable to reach the backup file '$backupDir'" -ForegroundColor Red
        exit
    }

    $dirs = dir $backupDir | ?{$_.PSISContainer}

    foreach ($d in $dirs) {
        $Component = $null

		$Component = GetComponentFromName $d.Name
		if ($Component -eq $null -or $Component.Host -eq $null) {
			Write-Host "Could not pass $($d.Name) as a Dynatrace component"
			continue
		}

        # Stop Dynatrace service and disable auto service-restart script task 
        StopServiceAndTasks $Component
        $restoreBase = GetDynatraceComponentPath $Component.Host $Component.Container

        $files = get-childitem -Path $d.FullName
        foreach ($file in $files) {
            if ($file -is [System.IO.DirectoryInfo] -and ($file.Name -match "CAS" -or $file.Name -match "RUM Console" -or $file.Name -match "ADS")) {
                if ($partial) { # Partial copy - only copying over individual files: Not the full component config
                    $subFiles = get-childitem -Path $file.FullName -recurse | where {! $_.PSIsContainer}
                    foreach ($sf in $subFiles) {
                        $relativePath = $sf.FullName.Substring($d.FullName.Length + 1)
                        $restorePath = "$restoreBase\$relativePath"
                        Copy-Item -Path $sf.FullName -Destination $restorePath -Force
                    }
                } else { # Full Restore - Wipe and copy over in bulk
                    Copy-Item -Path $file.FullName -Destination $restoreBase -Force -Recurse
                }
            } elseif ($file.Name -match "$($Component.DB).bak") {
                $localTempBackup = "\\$($Component.Host)\D$\tmp\$($Component.DB).bak"
                RestoreComponentDatabase $file.Fullname $localTempBackup $Component.Instance $Component.DB
            }
        }
        # Start Dynatrace service and re-enable auto service-restart script task
        StartServiceAndTasks $Component
    }
}

# TODO
#function RestoreFromS3Backup([String]$backupFolder) {
#}

# Enable or disable a Windows scheduled task
function ScheduledTaskHandler($Component, [String]$taskName, [Bool]$enable) {
    if ($enable) { # ENABLE
        Invoke-Command -Computername $Component.Host -ArgumentList $taskName -ScriptBlock {
            param($taskName)
            Enable-ScheduledTask -TaskName $taskName > $null
        }
    } else { # DISABLE
        Invoke-Command -Computername $Component.Host -ArgumentList $taskName -ScriptBlock {
            param($taskName)
            Disable-ScheduledTask -TaskName $taskName > $null
        }
    }
}

# Return the full list of every CAS (Prod, Dev, Preprod, sandbox)
function GetAllCASServers() {
    $prod = GetProdCASServers
    $preprod = GetPreprodCASServers
    $dev = GetDevCASServers
    $sandbox = GetSandboxCASServers

    return $prod + $preprod + $dev + $sandbox
}

# Return the full list of every ADS (Prod, Dev, Preprod, sandbox)
function GetAllADSServers() {
    $prod = GetProdADSServers
    $preprod = GetPreprodADSServers
    $dev = GetDevADSServers
    $sandbox = GetSandboxADSServers

    return $prod + $preprod + $dev + $sandbox
}

# Return the full list of every RUM Console (Prod, Dev, Preprod, sandbox)
function GetAllRUMConsoles() {
    $prod = GetProdRumConsole
    $preprod = GetPreprodRumConsole
    $dev = GetDevRumConsole
    $sandbox = GetSandboxRUMConsole

    return @($prod, $preprod, $dev, $sandbox)
}

# Return any custom list of CASs here
# Feel free to edit and change whenever
function GetCustomCAS() {
    $CASServers = @()

    # DELETE and REPLACE whenever
    #$CASServers += @{Host="<HOST>"; Container=null; Instance="<INSTANCE>"; DB="<DB>"}

    return $CASServers
}

    #Build number used to specify version to install. Numbering is "MM.mmbbb"
    #  MM = Major version (e.g. 17 for DCRUM 2017)
    #  mm = Major version (e.g. 04 for Service Pack 4)
    #  bbb = Build number (e.g. 215 fpr SP4 GA build)
function UpgradeRUMConsole($Console, [Decimal] $BuildNumber = 17.04215) {
    StopServiceAndTasks $Console
    UpgradeComponent $Console ([ComponentDCRUM]::RUMConsole) $BuildNumber
    Get-Job | Wait-Job

    # CONFIG
    $basePath = "$(GetDynatraceComponentPath $Console.Host $Console.Container)\RUM Console"

	# CUSTOMER SPECIFIC CONFIG - LARGE DCRUM CAS DEPLOYMENT
	# TODO Fix find/replace number multi match bug 400 -> 4000 -> 400000 -> 400000 ...
    $databaseProperties = "$basePath\workspace\configuration\database.properties"
    # Max number of databases connections allowed
    UpdateFileValue $databaseProperties "database.connections.maxActive=400" "database.connections.maxActive=4000"

    # Range of idle DB connections to be maintained
    UpdateFileValue $databaseProperties "database.connections.minIdle=10" "database.connections.minIdle=100"
    UpdateFileValue $databaseProperties "database.connections.maxIdle=30" "database.connections.maxIdle=300"
    
    # Max number of server threads maintained
    $executorProperties = "$basePath\workspace\configuration\executors.properties"
    UpdateFileValue $executorProperties "guiAction.threads=30" "guiAction.threads=300"
    UpdateFileValue $executorProperties "serverThreadPoolExecutor.threads=400" "serverThreadPoolExecutor.threads=4000"
    UpdateFileValue $executorProperties "scheduledExecutor.threads=30" "scheduledExecutor.threads=1200"

    # Decrease frequency of RUM Console device health checking
    $jobsProperties = "$basePath\workspace\configuration\jobs.properties"
    UpdateFileValue $jobsProperties "job.get.health.repeatInterval=5" "job.get.health.repeatInterval=30"
     
    # Decrease frequency of RUM Console checking NFC health of all connected AMDs
    UpdateFileValue $jobsProperties "job.get.data.nfc.repeatInterval=5" "job.get.data.nfc.repeatInterval=30"

    # Decrease frequency of RUM Console checking AppMon System Profiles of all connected devices
    UpdateFileValue $jobsProperties "job.get.data.dt.repeatInterval=5" "job.get.data.dt.repeatInterval=30"

    # Decrease frequency of RUM Console checking Universal Decode status of all connected AMDs
    UpdateFileValue $jobsProperties "job.get.data.universalDecode.repeatInterval=5" "job.get.data.universalDecode.repeatInterval=30"

    # Decrease frequency of RUM Console checking the type and installed version of all connected devices
    UpdateFileValue $jobsProperties "job.get.typeversion.repeatInterval=5" "job.get.typeversion.repeatInterval=30"

    # Stop excessive logging in the RUM Console logs
    $logback = "$basePath\workspace\configuration\logback.xml"
    UpdateFileValue $logback "<logger name=`"com.dynatrace.console.security`" level=`"DEBUG`" />" "<logger name=`"com.dynatrace.console.security`" level=`"INFO`" />"
    AddLineToFile $logback "<logger name=`"com.dynatrace.console.security`" level=`"INFO`" />" "<logger name=`"com.compuware.configuration.jetty.server.AuthenticationHandler`" level=`"ERROR`" />"

    # Increase number of jetty threads allowed
    $jettyxml = "$basePath\workspace\configuration\jetty\etc\jetty.xml"
    UpdateFileValue $jettyxml "<Property name=`"threads.max`" default=`"200`"/>" "<Property name=`"threads.max`" default=`"3000`"/>"

    # Increase queue size for HTTPS requests
    $jettyHttps = "$basePath\workspace\configuration\jetty\etc\jetty-https.xml"
    AddLineToFile $jettyHttps "<Set name=`"idleTimeout`"><Property name=`"https.timeout`" default=`"30000`"/></Set>" "<Set name=`"acceptQueueSize`">1000</Set>"
    
    StartServiceAndTasks $Console
}

function UpgradeCAS($CAS, [Decimal]$BuildNumber = 18.0195) {
    StopServiceAndTasks $CAS
    UpgradeComponent $CAS ([ComponentDCRUM]::CAS) $BuildNumber
}

function UpgradeADS($ADS) {
    StopServiceAndTasks $ADS
    UpgradeComponent $ADS ([ComponentDCRUM]::ADS)
}

# Enable scheduled tasks and watchdog service
function StartServiceAndTasks($Component) {
    $scheduledTask1 = "S_5min Script"
    $scheduledTask2 = "WSUS_Update"
    StartDynatraceService $Component
    ScheduledTaskHandler $Component $scheduledTask1 $true
    ScheduledTaskHandler $Component $scheduledTask2 $true
}

# Disabled scheduled tasks that could start the watchdog service
# and stop the watchdog service
function StopServiceAndTasks($Component) {
    $scheduledTask1 = "S_5min Script"
    $scheduledTask2 = "WSUS_Update"
    ScheduledTaskHandler $Component $scheduledTask1 $false
    ScheduledTaskHandler $Component $scheduledTask2 $false
    StopDynatraceService $Component
}

function RestartServiceAsJob($Component) {
    Write-Host "Restarting Dynatrace Service - $($Component.Host)$($Component.Container)"

    if ([String]::IsNullOrEmpty($Component.Container)) { # PHYSICAL SERVER
        Invoke-Command -Computername $Component.Host -ScriptBlock {
            $scheduledTask1 = "S_5min Script"
            $scheduledTask2 = "WSUS_Update"

            # Stop
            Disable-ScheduledTask -TaskName $scheduledTask1
            Disable-ScheduledTask -TaskName $scheduledTask2
            cmd /c 'NET Stop "WatchdogService"' > $null

            Start-Sleep -s 10

            # Start
            cmd /c 'NET Start "WatchdogService"' > $null
            Enable-ScheduledTask -TaskName $scheduledTask1
            Enable-ScheduledTask -TaskName $scheduledTask2
        } -AsJob
    } else { # CONTAINER
        $containerName = "$($Component.Host)$($Component.Container)"
        Invoke-Command -Computername $Component.Host -ArgumentList $containerName -ScriptBlock {
            param($containerName)

            $scheduledTask1 = "S_5min Script"
            $scheduledTask2 = "WSUS_Update"

            # Stop
            Disable-ScheduledTask -TaskName $scheduledTask1
            Disable-ScheduledTask -TaskName $scheduledTask2
            docker exec $containerName cmd /c 'NET Stop "WatchdogService"' > $null

            Start-Sleep -s 10

            # Start
            docker exec $containerName cmd /c 'NET Start "WatchdogService"' > $null
            Enable-ScheduledTask -TaskName $scheduledTask1
            Enable-ScheduledTask -TaskName $scheduledTask2
        } -AsJob
    }
}

function GetPhysicalServers() {
    $PhysicalServers = @()
    $PhysicalServers += "<SERVER_NAME>"
    return $PhysicalServers
}

##### /CORE FUNCTIONS

##### HELPER FUNCTIONS #####

# Confirm Library is reachable
function TestDCRUMLibrary() {
    Write-Host "TEST DCRUM LIBRARY"
}

# Replace a string in one file with another
function UpdateFileValue([String]$filePath, [String]$oldValue, [String]$newValue) {
    $message = ""

    if (!(Test-Path $filePath)) {
        $message = "`n$filepath - NOT FOUND"
        return $message
    }

    $content = Get-Content $filePath
    if ($content -ne $null) {
        $content = $content.replace($oldValue, $newValue)
        Set-Content $filePath $content
        $message = "`nReplaced '$oldValue' with '$newValue' in $filePath"
    } else {
        $message = "`n$filepath - CONTENT error"
    }

    return $message
}

# Return a bool of whether a docker container with that name already exists
function ContainerExists([String]$Containername) {
    $exists = $true

    # Check that the output of 'docker ps' doesn't include the container name
    $containers = docker ps
    if (!($containers -match $Containername)) {
        $exists = $false
    }

    return $exists
}

# Compress a folder into a .zip archive
function CompressZipArchive([String]$tempFolder, [String]$backupFolder=$null) {
    if (Test-Path $tempFolder) {
        Write-Host "Compressing $folder to a .zip archive..."
    } else {
        Write-Host "Folder to compress not found" -ForegroundColor Red
        return
    }

    # If a backup isn't provided - assume the same directory
    if ($backupFolder -eq $null) {
        $backupFolder = $tempFolder
    }

    $zipName  = Split-Path $tempFolder -leaf
    $backupZip = "$backupFolder\$zipName.zip"

    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::CreateFromDirectory($tempFolder, $backupZip)

    if ($?) {
        Remove-Item -Path $tempFolder -Recurse -Force
    }
}

# Get the path to the dynatrace install directory
# Works for containers and physical servers
function GetDynatraceComponentPath([String]$hostname, [String]$container) {
    $CASPath = $null

    if([String]::IsNullOrWhiteSpace($container)) {
        # Physical
        $CASPath = "\\$hostname\D$\Program Files\Dynatrace"
    } else {
        # Container
        $CASName = "$($hostname)$($container)"
        $CASPath = "\\$hostname\D$\containers\$CASName\Program Files\Dynatrace"
    }

    return $CASPath
}

# Run a command on a remote server (Physical or container)
function InvokeRemoteCommand($Component, $remoteCommand) {
    if ([String]::IsNullOrEmpty($Component.Container)) { # PHYSICAL SERVER
        Invoke-Command -Computername $Component.Host -ArgumentList $remoteCommand -ScriptBlock {
            param($containerName, $remoteCommand)
            cmd /c "$remoteCommand" > $null
        }
    } else { # CONTAINER
        $containerName = "$($Component.Host)$($Component.Container)"
        Invoke-Command -Computername $Component.Host -ArgumentList ($containerName, $remoteCommand) -ScriptBlock {
            param($containerName, $remoteCommand)
            docker exec $containerName cmd /c "$remoteCommand" > $null
        }
    }
}

# Poll a report server to determine whether it is running
# TODO HTTPS
function ValidWebResponseStatus([String]$URL) {
    # Cannot validate RUM Console - or other HTTPS.

    $ok = $false
    # Give the report server some time to start
    Start-Sleep -s 10
    $HTTP_Request = [System.Net.WebRequest]::Create("$URL")
    try {
        $HTTP_Response = $HTTP_Request.GetResponse()
    }
    catch [Net.WebException] {
        # Because GetResponse() throws an exception on 401 errors for some reason...
        $e = $_.Exception
        if ($e.Response -eq $null) {
           Write-Host $e.ToString() -ForegroundColor Red
           return $ok
        } else {
            $HTTP_Status = [int]$HTTP_Response.StatusCode
            $HTTP_Response = $e.Response
        }
    }

    $HTTP_Status = [int]$HTTP_Response.StatusCode
    Write-Host "URL: $url - returned a $HTTP_Status response" -ForegroundColor Yellow

    if ($HTTP_Status -eq 200 -or $HTTP_Status -eq 401) {
        $ok = $true
    }

    return $ok
}

# Backup a report server database to a backup directory
function BackupComponentDatabase([String]$backupFile, [String]$localTempBackup, [String]$instance, [String]$DBName) {
    Backup-SqlDatabase -ServerInstance $instance -Database $DBName -BackupFile $localTempBackup -CompressionOption On

    if (!(Test-Path $localTempBackup)) {
        Write-Host "Cannot reach DB backup File - $localTempBackup" -ForegroundColor Red
        exit
    }

    $localHash = (Get-FileHash $localTempBackup).hash
    Copy-Item -Path $localTempBackup -Destination $backupFile -Force

    if ($?) {
        if ($localHash -ne (Get-FileHash $backupFile).hash) {
            Write-Host "Backup File Checksum doesn't match: $backupFile - aborting upgrade"
            exit
        }
    } else {
        Write-Host "Could not copy the database backup over to the backup location - ABORTING"
        exit
    }

    Remove-Item -Path $localTempBackup -Force
}

# Resore a database from a database.bak file
function RestoreComponentDatabase([String]$backupFile, [String]$localTempBackup, [String]$instance, [String]$DBName) {
    Copy-Item -Path $backupFile -Destination $localTempBackup -Force
    
    # Ensure we have a local copy of the DB Backup
    if (!(Test-Path $localTempBackup)) {
        Write-Host "Error copying temp backup file" -ForegroundColor Red
        exit
    }

    $srv = new-object Microsoft.SqlServer.Management.Smo.Server($instance)
    # If the database exists then drop it otherwise Restore-SqlDatabase may fail if connections are open to it
    if ($srv.Databases[$DBName] -ne $null) {
        $srv.KillAllProcesses($DBName)
        $srv.KillDatabase($DBName)
    }

    Restore-SqlDatabase -ServerInstance $instance -Database $DBName -BackupFile $localTempBackup -ReplaceDatabase

    if (!$?) {
        Write-Host "Error restoring from backup - $backupFile"
        exit
    }

    Remove-Item -Path $localTempBackup -Force
}

# Add a new line to a file - insert after a provided value
function AddLineToFile([String]$filename, [String]$after, [String]$content) {
    (Get-Content $filename) -replace $after, "$&`n$content" | Set-Content $filename
}

# Prompt a user to confirm an actions
function ConfirmProcede([String]$message) {
    $confirm = Read-Host "$message"
    if ($confirm -ne 'y') {
        Write-Host "Aborted by user"
        Exit
    }
}

# Write a log to the console - and return it to be archived
function LogMessage([String]$message) {
    Write-Host $message -ForegroundColor Green
    return "`n$message"
}

# Stop the watchdog service
function StopDynatraceService($Component) {
    Write-Host "Stopping Dynatrace Service - $($Component.Host)$($Component.Container)"
    if ([String]::IsNullOrEmpty($Component.Container)) { # PHYSICAL SERVER
        Invoke-Command -Computername $Component.Host -ScriptBlock {
            cmd /c 'NET Stop "WatchdogService"' > $null
        }
    } else { # CONTAINER
        $containerName = "$($Component.Host)$($Component.Container)"
        Invoke-Command -Computername $Component.Host -ArgumentList $containerName -ScriptBlock {
            param($containerName)
            docker exec $containerName cmd /c 'NET Stop "WatchdogService"' > $null
        }
    }

    # Sleep for 10s to ensure process files have been freed
    Start-Sleep -s 10
}

# Start the watchdog service
function StartDynatraceService($Component) {
    Write-Host "Starting Dynatrace Service - $($Component.Host)$($Component.Container)"
    if ([String]::IsNullOrEmpty($Component.Container)) { # PHYSICAL SERVER
        Invoke-Command -Computername $Component.Host -ScriptBlock {
            cmd /c 'NET Start "WatchdogService"' > $null
        }
    } else { # CONTAINER
        $containerName = "$($Component.Host)$($Component.Container)"
        Invoke-Command -Computername $Component.Host -ArgumentList $containerName -ScriptBlock {
            param($containerName)
            docker exec $containerName cmd /c 'NET Start "WatchdogService"' > $null
        }
    }
}

##### /HELPER FUNCTIONS #####

##### PRIVATE FUNCTIONS #####

# Perform a service pack upgrade on a Reporting server
# Runs each upgrade as a job so can be run in parallel
# specify a unattend file for upgrade configuration
function UpgradeComponent($Component, [ComponentDCRUM]$type, [Decimal]$BuildNumber = 17.04215) {
    $softwareDir = $null
    $upgradeCommand = $null

    switch ($type) {
        CAS {
            switch ($BuildNumber)            
            {
                # nam 2018 SP1
                {$_ -eq 18.0195} {
                    $softwareDir = "<PATH>\nam1801upgradesp1\NAM Server\*"
                    $upgradeCommand = "<PATH>\Server180_SP1_setupAMD64.exe -i silent -f NAMServerSP1Upgrade.txt"        
                }
                 # Fallback to 2017 SP4
                default {
                    $softwareDir = "<PATH>\apm1704rumdc\CAS\*"
                    $upgradeCommand = "<PATH>\CAS170_SP4_setupAMD64.exe -i silent -f CASSP4Upgrade.txt"
                }
             }
        }
        ADS {
            $softwareDir = "<PATH>\apm1704rumdc\ADS\*"
            $upgradeCommand = "<PATH>\ADS170_SP4_setupAMD64.exe -i silent -f ADSSP4Upgrade.txt"
        }
        RUMCONSOLE {
            switch ($BuildNumber)
            {
                #2017 SP4
                {$_ -ge 17.04 -And $_ -lt 17.05} {
                    $softwareDir = "<PATH>\apm1704rumdc\Console\*"
                    $upgradeCommand = "C:\install\Console170_SP4_setupAMD64.exe -i silent -f ConsoleSP4Upgrade.txt"
                }
                #2017 SP6 Dev Build
                {$_ -eq 17.06257} {
                    $softwareDir = "<PATH>\apm1706devbuildrumdc\Console\*"
                    $upgradeCommand = "C:\install\Console_setupAMD64_1706_257.exe -i silent -f ConsoleSP6_257Upgrade.txt"
                }
                #nam 2018 SP1
                {$_ -eq 18.012551} {
                    $softwareDir = "<PATH>\nam1801upgradesp1\Console\*"
                    $upgradeCommand = "C:\install\Console180_SP1_setupAMD64.exe -i silent -f NAMConsoleSP1Upgrade.txt"
                }
                #nam 2018 SP2
                {$_ -eq 18.022580} {
                    $softwareDir = "<PATH>\nam1802devbuild\Console\*"
                    $upgradeCommand = "C:\install\Console_setupAMD64.exe -i silent -f NAMConsoleSP1Upgrade.txt"
                }
                # Fallback to 2017 SP4
                default {
                    $softwareDir = "<PATH>\apm1704rumdc\Console\*"
                    $upgradeCommand = "C:\install\Console170_SP4_setupAMD64.exe -i silent -f ConsoleSP4Upgrade.txt"
                }
            } 
        }
        default {
            # no type specified
            exit
        }
    }

    Write-Host "Upgrading: $($Component.Host)$($Component.Container)"
    if ([String]::IsNullOrEmpty($Component.Container)) { # PHYSICAL SERVER
        $installDir = "\\$($Component.Host)\D$\install"
        # TODO - Generalise for other physical components
        switch ($BuildNumber)            
        {
            # nam 2018 SP1
            {$_ -eq 18.0195} {
                $upgradeCommand = "$installDir\Server180_SP1_setupAMD64.exe -i silent -f NAMServerSP1Upgrade.txt"        
            }
                # Fallback to 2017 SP4
            default
            {
                $upgradeCommand = "$installDir\CAS170_SP4_setupAMD64.exe -i silent -f CASSP4Upgrade.txt"
            }
        }
        
        if (!(Test-Path $installDir)) {
            New-Item -ItemType Directory -Force -Path $installDir
        }
        Copy-Item $softwareDir $installDir -recurse -Force
        ReplaceSilentCASProperties $Component $installDir

        Invoke-Command -Computername $Component.Host -ArgumentList ($upgradeCommand, $installDir) -ScriptBlock {
            param($upgradeCommand)
            cmd /c "$upgradeCommand" > $null
        } -AsJob
    } else { # CONTAINER
        $installDir = "\\$($Component.Host)\D$\containers\install"
        Copy-Item $softwareDir $installDir -recurse -Force
        ReplaceSilentCASProperties $Component $installDir $BuildNumber

        $containerName = "$($Component.Host)$($Component.Container)"
        Invoke-Command -Computername $Component.Host -ArgumentList ($containerName, $upgradeCommand) -ScriptBlock {
            param($containerName, $upgradeCommand)
            docker exec $containerName cmd /c "$upgradeCommand"
        } -AsJob
    }

    #rm "$installDir\*"s > $null # Don't remove the install directory: Other threads could be using it
}
 
function ReplaceSilentCASProperties($CAS,$installDir,[Decimal]$BuildNumber) {
    if ($BuildNumber -eq 18.0195){
		$installProperties = "$installDir\NAMServerSP1Upgrade.txt"
		# Won't work for physical CAS
		$CASIP = MapDCRUMHostnameToIpAddress $CAS.Host $CAS.Container
		$CASURL = "$($CAS.Host)$($CAS.Container).maas.csda.gov.au"
		$SSLURL = "https://$($CASURL):443"
		$HTTPURL = "http://$($CASURL):80"
		UpdateFileValue $installProperties "PRIVATE_ADDRESS=<ADDRESS>" "PRIVATE_ADDRESS=$CASIP"
		UpdateFileValue $installProperties "SSL_URL=<SSL_URL>" "SSL_URL=$SSLURL"
		UpdateFileValue $installProperties "HTTP_URL=<HTTP_URL>" "HTTP_URL=$HTTPURL"
		UpdateFileValue $installProperties "SSO_KEY_COMMON_NAME=<SSO_KEY_COMMON_NAME>" "SSO_KEY_COMMON_NAME=$CASURL"
    }   
}

# Manually add each primary CAS here
function GetPrimaryCasServers() {
    $CASServers = @()
	
    $CASServers += @{Host="<HOST>"; Container=$null; Instance="<INSTANCE>"; DB="<CAS>"}

    return $CASServers
}

function GetPreprodCASServers() {
    $CASServers = @()

    $CASServers += @{Host="<HOST>"; Container=$null; Instance="<INSTANCE>"; DB="<CAS>"}

    return $CASServers
}

function GetSandboxCASServers() {
    $CASServers = @()

    $CASServers += @{Host="<HOST>"; Container=$null; Instance="<INSTANCE>"; DB="<CAS>"}
    
    return $CASServers
}

function GetDevCASServers() {
    $CASServers = @()

    $CASServers += @{Host="<HOST>"; Container=$null; Instance="<INSTANCE>"; DB="<CAS>"}

    return $CASServers
}

function GetProdCASServers() {
    $CASServers = @()

	# Loops are your friend for adding many
	
    $CASServers += @{Host="<HOST>"; Container=$null; Instance="<INSTANCE>"; DB="<CAS>"}

    return $CASServers
}

function FilterPrimaryCAS($CASServers, [Bool]$negation=$false) {
    $primaryCASNames = @()
    # Main
    $primaryCASNames += "<CAS_NAME>" # CLUSTER 1

    $filteredList = $CASServers
    if ($negation) {
        $filteredList =  $CASServers | Where {$primaryCASNames -NotContains "$($_.Host)$($_.Container)"}
    } else {
        $filteredList =  $CASServers | Where {$primaryCASNames -Contains "$($_.Host)$($_.Container)"}
    }

    return $filteredList
    
}

function FilterFailoverCAS($CASServers, [Bool]$negation=$false) {
    $failoverCASNames = @()
	
    $failoverCASNames += "<CAS_NAME>"

    $filteredList = $CASServers
    if ($negation) {
        $filteredList =  $CASServers | Where {$failoverCASNames -NotContains "$($_.Host)$($_.Container)"}
    } else {
        $filteredList =  $CASServers | Where {$failoverCASNames -Contains "$($_.Host)$($_.Container)"}
    }

    return $filteredList
}

function FilterMasterCAS ($CASServers, [Bool]$negation=$false) {
    $masterCASNames = @()
    # Main
    $masterCASNames += "<CAS_NAME>"

    $filteredList = $CASServers
    if ($negation) {
        $filteredList =  $CASServers | Where {$masterCASNames -NotContains "$($_.Host)$($_.Container)"}
    } else {
        $filteredList =  $CASServers | Where {$masterCASNames -Contains "$($_.Host)$($_.Container)"}
    }

    return $filteredList
}

function FilterNodeCAS($CASServers, [Bool]$negation=$false) {
    # !(MASTER || PRIMARY || FAILOVER)

    $filteredList = $CASServers
    $filteredList = FilterFailoverCAS $filteredList (!$negation)
    $filteredList = FilterPrimaryCAS $filteredList  (!$negation)
    $filteredList = FilterMasterCAS $filteredList (!$negation)
    
    return $filteredList
}

function FilterPhysicalCAS($CASServers, [Bool]$negation=$false) {
    $filteredList = $CASServers

    if ($negation) {
        $filteredList = $CASServers | Where-Object { !([String]::IsNullOrEmpty($_.Container)) }
    } else {
       $filteredList = $CASServers | Where-Object { [String]::IsNullOrEmpty($_.Container) }
    }
    
    return $filteredList
}

function FilterContainerCAS($CASServers, [Bool]$negation=$false) {
    return FilterPhysicalCAS $CASServers (!$negation)
}

function GetProdADSServers() {
    $ADSServers = @()
    # No ADS in use in prod
    return $ADSServers
}

function GetPreprodADSServers() {
    $ADSServers = @()
    $ADSServers += @{Host="<HOST>"; Container="$null"; Instance="<INSTANACE>"; DB="<DB>"}

    return $ADSServers
}

function GetSandboxADSServers() {
    $ADSServers = @()
    # No ADS
    return $ADSServers
}

function GetDevADSServers() {
    $ADSServers = @()
    $ADSServers += @{Host="HOST"; Container="$null"; Instance="<INSTANCE>"; DB="<DB>"}

    return $ADSServers

}

function GetDevRumConsole() {
    return @{Host="HOST"; Container="$null"; Instance="<INSTANCE>"; DB="<DB>"}
}

function GetPreprodRumConsole() {
    return @{Host="HOST"; Container="$null"; Instance="<INSTANCE>"; DB="<DB>"}
}

function GetSandboxRumConsole() {
    return @{Host="HOST"; Container="$null"; Instance="<INSTANCE>"; DB="<DB>"}
}

function GetProdRumConsole() {
    return  @{Host="HOST"; Container="C4"; Instance="<INSTANCE>"; DB="<DB>"}
}

function GetCasFromName([String]$CASName) {
    $CASServers = GetAllCASServers
    $CAS = $CASServers | Where-Object {"$($_.Host)$($_.Container)" -ieq $CASName}
    return $CAS
}

function GetADSFromName([String]$ADSName) {
    $ADSServers = GetAllADSServers
    $ADS = $ADSServers | Where-Object {"$($_.Host)$($_.Container)" -ieq $ADSName}
    return $ADS
}

function GetRUMConsoleFromName([String]$consoleName) {
    $Consoles = GetAllRUMConsoles
    $Console = $Consoles | Where-Object {"$($_.Host)$($_.Container)" -ieq $consoleName}
    return $Console
}

##### /PRIVATE FUNCTIONS #####