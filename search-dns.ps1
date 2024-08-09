<#
    .SYNOPSIS
    DNS Search script v1

    .DESCRIPTION
    Script takes a string input and working through all the primary DNS zones on the local DNS Server returns all records that match the string. In addition there are several optional filters available to either include or exclude zonenames, hostnames and recordtypes. Filtering on mutiple strings is possible using regex, eg -includerecordtype "MX|CNAME|PTR"

    .NOTES
    Written by Keith Langmead - August 2013

    .PARAMETER searchstr
    Takes an optional string input which is used to search against all zone records for a match. Regex strings can be used.

    .PARAMETER zonenamefilter
    Takes an optional string input which is used to filter the zone list being searched. Entire domain names, partial names and regex strings can be used.

    .PARAMETER excludehost
    Takes an optional string input used to exclude records where the hostname matches all or part of the string. Accepts Regex values.

    .PARAMETER includehost
    Takes an optional string input used to exclusively include records where the hostname matches all or part of the string. Accepts Regex values.

    .PARAMETER excluderecordtype
    Takes an optional string input used to exclude specified record types. Accepts Regex values.

    .PARAMETER includerecordtype
    Takes an optional string input used to exclusively include specified record types. Accepts Regex values.

    .PARAMETER computername
    Runs the script against the specified DNS server. Defaults to the local machine if not specified.

    .PARAMETER zoneonly
    If used this alters the output to return only the zone names that contain matches, not the individual records within the zone.

    .EXAMPLE
    .\search-dns "myrecord"
    Search all DNS zones for records including the string "myrecord".

    .EXAMPLE
    .\search-dns -searchstr "192.168.0.1" -zonenamefilter "mydomain" -excludehost "www|@"
    Search all DNS zones containing "mydomain" in their name for records pointing to "192.168.0.1" and exclude records with a hostname of "www" or "@".
    
    .EXAMPLE
    .\search-dns -searchstr "mydomain" -zonenamefilter ".info" -excluderecordtype "MX|NS"
    Search all records excluding MX and NS records in all .info domains for the string "mydomain".

    .EXAMPLE
    .\search-dns -searchstr "mail.mydomain.com" -includerecordtype "MX" -zoneonly
    Search all MX records in all zones that contain "mail.mydomain.com" and then list the zone names not the records themselves.

    .EXAMPLE
    .\search-dns -searchstr "192.168.0.1" -zonenamefilter "mydomain" -includehost "www" -includerecordtype "A" -computername dc2
    Search for a specific record on a machine other than localhost, for instance to confirm that a locally added record has replicated to another name server.
#>

Param(
    [parameter(position=1)]
    [string]$searchstr,

    [parameter(position=2)]
    [string]$zonenamefilter,

    [parameter(position=3)]
    [string]$excludehost,

    [parameter(position=4)]
    [string]$includehost,

    [parameter(position=5)]
    [string]$excluderecordtype,

    [parameter(position=6)]
    [string]$includerecordtype,

    [parameter(position=7)]
    [string]$computername=$env:COMPUTERNAME,

    [parameter(position=8)]
    [switch]$zoneonly
)

Function SearchZone ($ZoneArg)
# Function takes the current zone as an argument, filters the required records based on which options have been
# passed to the script via the script parameters
{
    $current=get-dnsserverresourcerecord -zonename $ZoneArg.zonename -ComputerName $computername
    if ($excludehost -ne "")
    {
        # Filters out records where the hostname matches $excludehost so they're not displayed
        $current=@($current | where-object {$_.Hostname -notmatch $excludehost})
    }
    if ($excluderecordtype -ne "")
    {
        # Filters out records where RecordType matches $excluderecordtype so they're not displayed
        $current=@($current | where-object {$_.RecordType -notmatch $excluderecordtype})
    }
    if ($includehost -ne "")
    {
        # Exclusively include records where HostName matches $includehost
        $current=@($current | where-object {$_.Hostname -match $includehost})
    }
    if ($includerecordtype -ne "")
    {
        # Exclusively include records where RecordType matches $includerecordtype
        $current=@($current | where-object {$_.RecordType -match $includerecordtype})
    }
    # Exclusively include records where RecordData matches $searchstr. Works through each property
    # type to include the relevant records in the output
    $currentrec=@($current | where-object {$_.RecordData.ipv4address -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.HostNameAlias -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.MailExchange -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.DomainName -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.DescriptiveText -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.PrimaryServer -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.NameServer -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.IPv6Address -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.RecordData.PtrDomainName -match $searchstr})
    $currentrec=$currentrec + @($current | where-object {$_.HostName -match $searchstr})    
    return $currentrec
}

# Generate a list of all primary zones, eg exclude secondaries
$zonelist=get-dnsserverzone -ComputerName $computername | Where-Object {$_.zonetype -eq 'Primary'}
# If something's entered in $zonenamefilter filter zones to exclude them
$zonelist=$zonelist | Where-Object {$_.zonename -match $zonenamefilter}

# Generate table headers in output since otherwise when it displays automatically the first zonename 
# is listed above the headers. Display alternate header is -zoneonly switch used.
if ($zoneonly -ne $TRUE)
{
    write-host "HostName                  RecordType TimeStamp            TimeToLive      RecordData"
    write-host "--------                  ---------- ---------            ----------      ----------"
}
else
{
    write-host "Zones containing matching values:"
    write-host "---------------------------------"
}

# Loop through the list of zones
foreach ($zone in $zonelist)
{
    # Pass current zone to search zone function and retrieve results
    $zonerecord=SearchZone $zone 
    if ($zonerecord -ne $NULL)
    {
        if ($zoneonly -ne $TRUE)
        {
            # Output results grouped by zone
            write-host
            write-host "Domain - " $zone.zonename
            $zonerecord | format-table -hidetableheaders
        }
        else
        {
            # Output zone names only that contain matches
            write-host $zone.zonename
        }
    }
}
