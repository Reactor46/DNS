#######################################################################################
#                                                                                     #
# Copyright (c) Microsoft Corporation.                                                #
#                                                                                     #
# Script:    Add Entry to DNS                                                         #
#                                                                                     #
# Written By Shawn Gibbs                                                              #
#                                                                                     #
#######################################################################################
#                                                                                     #
# Usage:                                                                              #
# AddEntryToDns.ps1 <FQDN Of DNS Server> <Server Name Alias> [IP Address to point to] #
#                                                                                     #
#  IP Address is optional, if left blank the script will use first IP off adapter 1  #
#                                                                                     #
#######################################################################################

if ($args.Count -lt 2 -or $args.count -gt 3) 
 { 
 $ScriptName = $MyInvocation.MyCommand.Name
 $Instructions = @"

    usage: $ScriptName <FQDN Of DNS Server> <Server Name Alias> [IP Address to point to]
    
    This script creates an A Record in DNS

    Required Paramaters:

    <FQDN Of DNS Server>:   
    This is the Full Qualified Domain Name of the DNS Server. ex: dns.contoso.com

    <Server Name Alias>:        
    This is the alias you wish to redirect to the IP address, it shouldn't be FQDN.

    Optional Paramaters:

    [IP Address to point to]   
    This is the IP address in IPv4 format you wish the alias to redirect to. This is an 
    optional setting, if left blank it will fill in with it's own IP address.
"@ 
    write-output $Instructions
    break

 }
$server = $args[0]
$serverSplit = $server.split(".")
$zone = $serverSplit[1] + "." + $serverSplit[2]
$name = $args[1]  
$address = $args[2]

# Test if an value has been submitted for IP address and if not get local host name and then IP address in IPv4 format
if(!$address)
{
    $hn = $(Get-WmiObject Win32_Computersystem).name
    $address = Get-NetIPAddress –AddressFamily IPv4 | Where-Object -FilterScript {$_.InterfaceIndex -gt 1} | Select-Object IPAddress
}

Add-DnsServerResourceRecordA -ComputerName $server -Name $name -ZoneName $zone -AllowUpdateAny -IPv4Address $address.IPAddress -TimeToLive 01:00:00  
