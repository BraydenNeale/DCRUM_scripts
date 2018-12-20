# DCRUM SCRIPTS
A collection of useful scripts for automating many common tasks in large DCRUM deployments. <br>
DCRUM_libary.ps1 is the central library.

## DCRUM SCRIPT LIST
| Name | Parameters | Details |
| --- | --- | --- |
| DCRUM_Library | | A collection of objects and functions to automate DCRUM tasks. Documented within the script. Import to use |
| copy_config | **envFlag** The DCRUM env to target: prod, preprod, dev <br> **auto** ignore user prompts if automated | Copy over custom config files to each CAS in the environment <br> reportTime-custom.properties <br>dashboard-custom.properties <br> locations.config <br>|
| fixed_server_parallel_backup | **envFlag** the DCRUM env to target| Backup all CAS servers to a list of backup servers. Stripes them equally and runs in parallel |
| hide_sections | | Adds Javascript to hide the 'All report' sections that are specified within a blacklist |
| increase_HTTP_timeout | **y** switch to auto approve user prompts (false is default)<br> **envFlag** the DCRUM env to target | Updates CAS database userProperties DMI_AGGR_ROWS_TO_SEND |
| install_ADS_container | **container_to_install** container number (must be 4 for an ADS) <br> **Primary CIP** The IP of the primary ADS for setting the required-member in hazelcast (default is own IP <br> **envFlag** The DCRUM env to install into (Determines the RUM Console URL and token to use) | Creates a new Windows server container and installs an ADS into it, networking can be handled automatically. To be run from the host you are installing to|
| install_CAS_container | **container_to_install** container number (1-4) <br> **Primary CIP** The IP of the primary CAS for setting the required-member in hazelcast (default is own IP) <br> **envFlag** The DCRUM env to install into (Determines the RUM Console URL and token to use) | Creates a new Windows server container and installs a CAS into it, networking can be handled automatically. To be run from the host you are installing to|
| install_RUM_Console_container | **container_to_install** container number (1-4) <br> **envFlag** The DCRUM env to install into (sets the auth token | Creates a new Windows server container and installs a RUM Console into it, networking can be handled automatically. To be run from the host you are installing to|
| partial_restore_from_backup | **backupDir** the path to the director to restore from | Restores component files contained within the backup dir 1 at a time. Meaning that it only restores files that were changed (rather than blowing away the existing directory). It will take a lot longer if you use this for a full backup. |
| print_environment | **envFlag** the DCRUM env to target | Prints out a breakdown of the report servers in that environment. The counts and names of each: <br> Rum Console<br> Master CAS<br> Primary CAS<br> Seconday CAS<br> Failover CAS<br> ADS<br> Writes this to a specified temp file |
| remove_container | **Container_to_drop** the container number to remove | Drops the container, removes all of the component files and the database. To be run from the host you are removing from |
| restart_environment | **envFlag** The DCRUM env to target | Restarts every component in the environment. Stops the Dynatrace service and then restarts it. Prompts for each type |
| service_pack_upgrade | **envFlag** the DCRUM env to target | Performs a full in place service pack upgrade of all reporting sever components in the environment. The upgrade order is: Rum Console<br> Failover CAS<br> Master CAS<br>Primary CAS<br> Secondary CAS<br> ADS<br> Stops after each stage and prompts the user to perform and confirm a manual health check |
| stagger_CAS_start_time | **envFlag** The DCRUM env to target. <br> **auto** ignore user prompts if automated | staggers the time that CAS servers run the daily task to update table stats (and restart) by editing the task time in the tasks-100-hcbs.xml file. By default this happens at 12:30 - this time is changed to be 12:3x where x is the last digit of the CAS hostname (0-9). This is required to stop all CASs polling the RUM Console at the same time when they come online |
| sync_dashboard_icons | **envFlag** the DCRUM env to target. | Copies over custom icons and the dashboard-custom.properties file to all CAS servers in the environment |
| sync_pathces | **envFlag** the DCRUM env to target. <br> **ServicePackVersion** the SP version of the components (default is 2017 SP2). <br> **auto** ignore user prompts if automated | Used to copy required patches to each CAS in the environment |
