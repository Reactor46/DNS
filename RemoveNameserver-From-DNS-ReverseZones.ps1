##############################
## 							##
## Version 1 August 2016	##
## Alexandar Tanev			##
##							##
##############################

##############################
#The following section contains all input parameters
$DC = "USONVSVRDC03.USON.LOCAL" #Domain controller to be used
$nameserver = "msodc04.uson.local" #Nameserver to remove
#
##############################

$list = Get-DnsServer -ComputerName $DC | select -Property serverzone -ExpandProperty serverzone | where  {$_.isdsintegrated -eq "true" -and $_.isreverselookupzone -eq "true"} | select -Property zonename

foreach ($zone in $list ) {Remove-DnsServerResourceRecord -ComputerName $DC -ZoneName $zone.zonename -RRType Ns -Name "@" -RecordData $nameserver -Force}