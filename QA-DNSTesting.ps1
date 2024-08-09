$PriDNS = '147.61.233.17'
$SecDNS = '147.61.233.16'

Get-DnsClientServerAddress | Where-Object ("InterfaceAlias" -like "Ethernet*") | Select-Object InterfaceIndex