function Get-PublicDnsRecord{
<#
.SYNOPSIS
    Make some DNS query based on Stat DNS.
.DESCRIPTION
    Use Invoke-WebRequest on Stat DNS to resolve DNS query.
.EXAMPLE
    Get-PublicDnsRecord -DomaineNAme "ItForDummies.net" -DnsRecordType A,MX
.EXAMPLE
    Get-PublicDnsRecord -DomaineNAme "blog.abcloud.fr" -DnsRecordType A,MX
.PARAMETER DomaineName
    Domain name to query.
.PARAMETER DnsRecordType
    DNS type to query.
.INPUTS
.OUTPUTS
.NOTES
.LINK
    http://ItForDummies.net
#>
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateScript({[system.Net.dns]::GetHostAddresses("$_")})]
        [String]$DomaineName,

        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet('A','AAAA','CERT','CNAME','DHCIP','DLV','DNAME','DNSKEY','DS','HINFO','HIP','IPSECKEY','KX','LOC','MX','NAPTR','NS','NSEC','NSEC3','NSEC3PARAM','OPT','PTR','RRSIG','SOA','SPF','SRV','SSHFP','TA','TALINK','TLSA','TXT')]
        [String[]]$DnsRecordType
    )
    Begin{}
    Process{
        ForEach($Record in $DnsRecordType){
            $WebUrl = "http://api.statdns.com/{0}/{1}" -f $DomaineNAme,$Record
            $WebData = Invoke-WebRequest $WebUrl | select -ExpandProperty Content | ConvertFrom-Json | select -ExpandProperty answer
            $WebData | % {
                 New-Object -TypeName PSObject -Property @{
                    'Name'      = $_.name
                    'Type'      = $_.type
                    'IpAddress' = $_.rdata
                }
            }
        }
    }
    End{}
}