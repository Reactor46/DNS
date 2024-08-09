$zn = "Contoso.corp"
$dc = "lasdc02"
$Servers = Get-Content C:\LazyWinAdmin\DNS\DNSRemove.txt
ForEach($srv in $Servers){

#Get-DnsServerResourceRecord -ZoneName $zn -Name $srv -ComputerName $dc |
 #   Remove-DnsServerResourceRecord -Force -ZoneName $zn -ComputerName $dc }
 Resolve-DnsName $srv -Server $dc -Verbose }


Clear-DnsClientCache