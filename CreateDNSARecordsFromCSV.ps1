<# 
.SYNOPSIS
Creates A records for the specified zone and PTR from a CSV file.

.DESCRIPTION
Requires Powershell 3 or higher to work.

.PARAMETER CSVSourceFile
Takes a CSV Source file, needs to be formatted like
"Name","IP"
localhost,127.0.0.01

.PARAMETER Zone
Targeted DNS Zone

.PARAMETER DNSServer
The DNS Server responsible for the zone (if AD domain, the domain controller is a good guess)

.NOTES
Author: Jimmy Karlsson
Date: 2014-02-15
#>

[CmdLetBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [string]$CSVSourceFile,
    [Parameter(Mandatory=$True)]
    [string]$Zone,
    [parameter(Mandatory=$True)]
    [string]$DNSServer
)
    
#Imports the CSV file
$csv = Import-Csv -Path $CSVSourceFile

ForEach($i in $CSV)
{
    #Converts the [string] IP address from CSV to IPaddress datatype
    [ipaddress]$ip = $i.ip

    #Adds the DNS record and create a PTR
    Add-DnsServerResourceRecordA -ZoneName $Zone -Name $i.name -IPv4Address $ip  -CreatePtr -ComputerName $DNSServer
}