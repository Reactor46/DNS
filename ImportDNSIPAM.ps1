$Zones = Get-DnsServerZone -ComputerName baltdc3 | Where {$_.ZoneType -eq "Primary" -and $_.IsReverseLookupZone -eq $false}
$DNSIP = $Zones | ForEach-Object {get-dnsserverresourcerecord -ComputerName baltdc3 -ZoneName $_.ZoneName | WHERE {$_.RecordType -eq "A"} | Select-Object @{Name="IP Address";Expression={$_.RecordData.IPv4Address}}, @{Name="Device Name";Expression={$_.HostName}}, @{Name="Assignment Date";Expression={$_.TimeStamp}}, @{Name="Expiry Date";Expression={$_.TimeToLive + $_.TimeStamp}}  } 
$DHCPIP = Get-DhcpServerv4Scope -ComputerName baltdc3 | ForEach-Object {Get-DhcpServerv4Lease -ComputerName baltdc3 -ScopeId $_.ScopeId | Select-Object @{Name="IP Address";Expression={$_.ipaddress}}, @{Name="MAC Address";Expression={$_.clientid}}, @{Name="Device Name";Expression={$_.hostname}}, @{Name="Expiry Date";Expression={$_.leaseexpirytime}}, @{Name="Description";Expression={$_.description}}, @{Name="Assignment Type";Expression="Dynamic"}}
$IPs = @()
$RemoveIP = @()
ForEach ($IP in $DNSIP)
{
    If (-not($DHCPIP."IP Address" -contains $IP."IP Address"))
    {
        $IPs += $IP
    }
}
$IPs |  Export-Csv -Path C:\IPLogs\DNS.csv -force -NoTypeInformation
Import-IPAMAddress -Path C:\IPLogs\DNS.csv -AddressFamily IPv4 -force