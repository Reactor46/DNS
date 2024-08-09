Function Get-DNSCacheInfoFromRemoteCommandResults
{
    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER InputObject
        Object or array of objects returned from Get-RemoteCommandResults
    .EXAMPLE
        <Placeholder>
        
        Description
        -----------
        <Placeholder>

    .NOTES
        Author: Zachary Loeber
        Site: http://www.the-little-things.net/
        Requires: Powershell 2.0

        Version History
        1.0.0 - 09/20/2013
        - Initial release
    
        ** This is a supplement function to New-RemoteCommand and Get-RemoteCommandResults **
    #>
    [CmdletBinding()]
    PARAM
    (
        [Parameter(HelpMessage='Object or array of objects returned from Get-RemoteCommandResults')]
        $InputObject
    )
    BEGIN
    {
        $DNSCacheResults = @()
        $Results = @()
        $DNSTypes = @{
            '1' = 'A'
            '2' = 'NS'
            '5' = 'CNAME'
            '6' = 'SOA'
            '12' = 'PTR'
            '15' = 'MX'
            '16' = 'TXT'
            '17' = 'RP'
            '18' = 'AFSDB'
            '24' = 'SIG'
            '25' = 'KEY'
            '28' = 'AAAA'
            '29' = 'LOC'
            '33' = 'SRV'
            '35' = 'NAPTR'
            '36' = 'KX'
            '37' = 'CERT'
            '39' = 'DNAME'
            '42' = 'APL'
            '43' = 'DS'
            '44' = 'SSHFP'
            '45' = 'IPSECKEY'
            '46' = 'RRSIG'
            '47' = 'NSEC'
            '48' = 'DNSKEY'
            '49' = 'DHCID'
            '50' = 'NSEC3'
            '51' = 'NSEC3PARAM'
            '52' = 'TLSA'
            '55' = 'HIP'
            '99' = 'SPF'
            '249' = 'TKEY'
            '250' = 'TSIG'
            '257' = 'CAA'
            '32768' = 'TA'
            '32769' = 'DLV'
        }
    }
    PROCESS
    {
        $Results += $InputObject
    }
    END
    {
        Foreach ($result in $Results)
        {
            $CacheEntries = @()
            $entry = $result.CommandResults -match 'Record '
            $entry.count
            for ($i=0; $i -lt $entry.Count; $i+=3)
            {
                $cacheentryprops = @{
                  Name=$entry[$i].toString().Split(":")[1].Trim()
                  Type=$DNSTypes[($entry[$i+1].toString().Split(":")[1].Trim())]
                  Value=$entry[$i+2].toString().Split(":")[1].Trim()
                }
                $CacheEntries += New-Object PSObject -Property $cacheentryprops
            }
            $DNSCacheResultProp = @{
                'PSComputerName' = $result.PSComputerName
                'PSDateTime' = $result.PSDateTime
                'ComputerName' = $result.ComputerName
                'CacheEntries' = $CacheEntries
            }
            $DNSCacheResults += New-Object PSObject -Property $DNSCacheResultProp
        }
        $DNSCacheResults
    }
}