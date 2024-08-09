#DNSSEC Demo creation script
#Run this script from the non-auth server after all machines have been joined to contoso.com

#Setup conditional forwarder - corp.contoso.com
Add-DnsServerConditionalForwarderZone -Name corp.contoso.com -MasterServers 20.0.0.1, 20.0.0.5 -ComputerName non-auth

#function to setup zones for demo
Function Setup-DemoZones ($DCs)
{
    foreach ($DC in $DCs) 
    {
        Add-DnsServerPrimaryZone -Name ContosoUniversity.edu -ZoneFile contosouniversity.edu.dns -DynamicUpdate None -ComputerName $DC.Name
        Add-DnsServerResourceRecordA -ZoneName ContosoUniversity.edu -Name www -IPv4Address $DC.IP4Address -ComputerName $DC.Name -TimeToLive 00:00:05

    } 
    Return
}

#Get ip addresses for DCs
$DC1 = Resolve-DnsName -Name dns-dc1 -Type A
$DC2 = Resolve-DnsName -Name dns-dc2 -Type A
$DCs = ($DC1, $DC2)


#setup zones
Setup-DemoZones $DCs

#Setup conditional forwarder - contosouniversity.edu
Add-DnsServerConditionalForwarderZone -Name contosouniversity.edu -MasterServers $DC1.IP4Address -ComputerName non-auth





