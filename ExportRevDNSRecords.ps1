###########################################################
#		Author: Vikas SUkhija (http://msexchange.me)
#		Date: 5/23/2016
#		Modified:
#		Reviewer:
#		Decsription: Export reverse DNS records
#		Prereq: http://dnsshell.codeplex.com/ (already downloaded)
###########################################################

$date1 = get-date -format d
$date1 = $date1.ToString().Replace("/","-")

$logs = ".\Logs" + "\" + "Processed_" + $date1 + "_.log"
$csv = ".\" + "Revrecords_" + $date1 + "_.csv"

Start-Transcript -Path $logs

$collection = @()

##############Import DNS Module and extract report#########

import-module .\DnsShell\DnsShell.psd1

$dnserver = "DNSHostName" ######update dns server Name

$revzone = Get-DnsZone -Server $dnserver | ? {$_.ZoneName -like '*in-addr.arpa'}

$exportrevdns = $revzone | Get-DnsRecord -RecordType PTR  | Select Hostname,Name,TTL,RecordType,ZoneName

$exportrevdns | foreach-object{

$Hostname = $_.Hostname
$Name = $_.Name
$TTL = $_.TTL
$RecordType = $_.RecordType
$ZoneName = $_.ZoneName

$IP1 = $Name.split(".")

$IP = $IP1[3] + "." +  $IP1[2] + "." + $IP1[1] + "." + $IP1[0]

$coll = "" | Select Hostname,IP,TTL,RecordType,ZoneName

$coll.Hostname = $Hostname
$coll.IP = $IP
$coll.TTL = $TTL
$coll.RecordType = $RecordType
$coll.ZoneName = $ZoneName
$collection += $coll

}
####################################################

$collection | export-csv $csv -notypeinfo

stop-transcript

#####################################################
