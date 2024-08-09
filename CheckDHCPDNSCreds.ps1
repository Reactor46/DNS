<#
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING 
BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, 
royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that 
You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees, 
that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights. 
Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm.
#>

Function DotNetPing
{
        param($computername)
	$Reachable = "FALSE"
	$Reply = $Null
	$ReplyStatus= $Null
	$ping = new-object System.Net.NetworkInformation.Ping
        Trap {continue}
	$Reply = $ping.send($computername)
	$ReplyStatus = $Reply.status
	If($ReplyStatus -eq "Success") {$Reachable ="TRUE"}
	else {$Reachable="FALSE"}
	$Reachable 
}              
##################################
Function EnumerateDCs
{
	$arrServers =@()
	$rootdse=new-object directoryservices.directoryentry("LDAP://rootdse")
	$Configpath=$rootdse.configurationNamingContext
	$adsientry=new-object directoryservices.directoryentry("LDAP://cn=Sites,$Configpath")
	$adsisearcher=new-object directoryservices.directorysearcher($adsientry)
	$adsisearcher.pagesize=1000
	$adsisearcher.searchscope="subtree"
	$strfilter="(ObjectClass=Server)"
	$adsisearcher.filter=$strfilter
	$colAttributeList = "cn","dNSHostName","ServerReference","distinguishedname"
	
	Foreach ($c in $colAttributeList)
	{
		[void]$adsiSearcher.PropertiesToLoad.Add($c)
	}
	$objServers=$adsisearcher.findall()
                		
	forEach ($objServer in $objServers)
        {
		$serverDN = $objServer.properties.item("distinguishedname")
		$ntdsDN = "CN=NTDS Settings,$serverDN"
		if ([adsi]::Exists("LDAP://$ntdsDN"))
		{
			$serverdNSHostname = $objServer.properties.item("dNSHostname")
			$arrServers += "$serverDNSHostname"
		}
		$serverdNSHostname=""
	}
        $arrServers
}
##################################
Function isRunningDHCP
{
	Param($computer)
	$DHCP = "FALSE"
	$Query = "SELECT Name, Status FROM Win32_Service WHERE (Name = 'DHCPServer') AND (State = 'Running')"
	Try
	{
		$DHCPRunning = Get-WmiObject -Query $Query -ComputerName $Computer -EA Stop
		If ($DHCPRunning){$DHCP = "TRUE"}
	}
	Catch {$DHCP = "FALSE"}
	Finally {$DHCP}
}
###################################
Function GetAltCreds
{
	Param($computer)
	$AltCreds = $Null
	Try
	{
		$Query = Netsh dhcp server "\\$computer" show dnscredentials
		$username = $Query[2].substring(14)
		$domain = $Query[3].substring(14)
		If ($username.length -eq 0){$AltCreds = "NULL"}
		Else {$AltCreds = "$domain\$username"}
	}
	Catch
	{
		$AltCreds = "Error.  Ensure DHCP management tools are installed."	
	}
	
	
	$AltCreds
}
##################################

$listofDCs = EnumerateDCs
$colofRecords = @()

ForEach ($DC in $listofDCs)
{
	Write-Host "Checking $DC" -foregroundcolor green
	$pingable = DotNetPing $DC
	$record = "" | select-object DCName,Reachable,RunningDHCP,AltCreds
	$record.DCName = $DC
	$record.Reachable = $pingable
	If ($pingable -eq "TRUE")
	{
		$runningDHCP = isRunningDHCP $DC
		If ($runningDHCP -eq "TRUE")
		{
			$record.RunningDHCP = "TRUE"
			$AltCreds = GetAltCreds $DC
			$record.AltCreds = $AltCreds
			

		}
		Else
		{
			$record.RunningDHCP = "FALSE"
			$record.AltCreds = "NA"
		}
				
	}
	Else 
	{
		$record.RunningDHCP = "NotReachable"
		$record.AltCreds = "NotReachable"
	}
	$colofRecords += $record

}

### Comment out the line below, to not display results on screen
$colofRecords

### Dump list to a file
If ($colofRecords){$colofRecords | export-csv .\DHCPDynamicDNS.csv}




