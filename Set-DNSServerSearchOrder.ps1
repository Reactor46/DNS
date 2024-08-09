function Set-DNSServerSearchOrder {
    Param(
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        $ComputerName=$Env:ComputerName,
        [String[]]$DNSServers = @("10.10.10.1","10.10.10.2")
        )

$NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -Filter "IPEnabled=TRUE"

foreach($NIC in $NICs) {$NIC.SetDNSServerSearchOrder($DNSServers) | out-null}
}