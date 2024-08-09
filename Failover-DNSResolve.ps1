$Websites = 'creditone.com','creditonebank.com','chat.creditonebank.com','images.creditonebank.com','prequal.creditonebank.com','accept.creditonebank.com','m.creditonebank.com'


$ExtDNS = @(
ForEach($Site in $Websites){
Resolve-DnsName  $Site -Server 8.8.8.8 -NoHostsFile | Select-Object Name, IPAddress
Resolve-DnsName  $Site -Server 8.8.4.4 -NoHostsFile | Select-Object Name, IPAddress
Resolve-DnsName  $Site -Server 4.2.2.2 -NoHostsFile | Select-Object Name, IPAddress
} )
$ExtDNS

$IntDNS = @(
ForEach($Site in $Websites){
Resolve-DnsName $Site -Server 192.168.11.91 -NoHostsFile | Select-Object Name, IPAddress
Resolve-DnsName $Site -Server 192.168.11.92 -NoHostsFile | Select-Object Name, IPAddress
} )
$IntDNS