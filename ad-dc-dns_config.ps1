# Author: Shawn Gibbs shawngib@microsoft.com
# Customer, Architecture, and Technologies - WSSC CAT
#
# Purpose: Configure Active Directory
# Arguments: <Local Admin Password> <Domain Name> [Data Drive]
# Example: ./ad-dc-dns_config.ps1 Pass@word1 tailspin.com D#
# Parameters to be modified to reflect variables from service template
$ScriptName = $MyInvocation.MyCommand.Nameif (($args.Count -le 1) -or ($args.Count -ge 4)) {  $Instructions = @"    usage: $ScriptName <Local Admin Password> <Domain Name> [Data Drive]        This script creates an Active Directory server    Required Paramaters:    <Local Admin Password>:       This is the same password used in the template configuration for local administrator.    <Domain Name>:            The domain used to create Active Directory and DNS trees.    Optional Parameters:    [Data Drive]    Optionally, the data drive for storing database, SYSVOL and log files can be entered."@         $EventLog = New-Object System.Diagnostics.EventLog('Application')
    $EventLog.MachineName = "."
    $EventLog.Source = "$ScriptName"
    $EventLog.WriteEntry("Script did not complete. $Instructions","Error", "1000")    exit }
 
$pass = $args[0]$domain = $args[1]
$driveLetter = $args[2]
$dataDrive = ""
$driveLetter = "D"
try{

# ToDo: Here we simply test if the drive letter entered as a param is actually a drive. This
#       should be more agressive testing for writable and available free space using Get-PSDrive.
#       Again for fast deploys we have control over we know attached drives and size but we 
#       are confirming here it exist and falling back if something went wrong attaching it.
if((New-Object System.IO.DriveInfo($driveLetter)).DriveType -ne 'NoRootDirectory')
{
    $dataDrive = $driveLetter + ":\Windows\"
}
else
{
    $dataDrive = "c:\Windows\"
}

$databasePath = $dataDrive + "NTDS"
$sysvolPath = $dataDrive + "SYSVOL"

Import-Module ADDSDeployment
$result = Install-ADDSForest `
-CreateDNSDelegation:$false `
-safemodeadministratorpassword (convertto-securestring $pass -asplaintext -force) `
-DatabasePath $databasePath `
-DomainMode "Win2012" `
-DomainName $domain `
-ForestMode "Win2012" `
-InstallDNS:$true `
-LogPath $databasePath `
-NoRebootOnCompletion:$false `
-SYSVOLPath $sysvolPath `
-force:$true

        # Writing an event log entry
        $EventLog = New-Object System.Diagnostics.EventLog('Application')
        $EventLog.MachineName = "."
        $EventLog.Source = "$ScriptName"
        $EventLog.WriteEntry("$result","Information", "1000")}catch [Exception]{    $EventLog = New-Object System.Diagnostics.EventLog('Application')
    $EventLog.MachineName = "."
    $EventLog.Source = "$ScriptName"
    $EventLog.WriteEntry("Script failed. The error message: $_.Exception.Message","Error", "1000")
    throw "$ScriptName failed to complete. $_.Exception.Message "
    }
