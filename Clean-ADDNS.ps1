
###############################################################################################################
# Script - Remove Stale DNS DC Records         Author:Juan Pablo Orphanos                                     #
# Description: This script is meant to be used during a DC forceful demotion (or Forest Recovery scenario)    #
# to cleanup all msdcs delegation zone stale records of non existent Domain controllers                       #
#                                                                                                             #
#                                                                                                             #
###############################################################################################################

param (
    $DCFQDN, 
    $DCIPAddress,
    $DomainFQDN
)


$msdcszone = "_msdcs." + $DomainFQDN


Get-DnsServerResourceRecord -ZoneName $msdcszone -ComputerName (Get-ADDomainController).HostName | Where-Object {$_.RecordData.IPv4Address.IPAddressToString -eq $DCIPAddress -or $_.RecordData.NameServer -eq $DCFQDN -or $_.RecordData.DomainName -eq $DCFQDN} | Remove-DnsServerResourceRecord -ZoneName $msdcszone -force