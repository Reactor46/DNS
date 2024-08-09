#requires -version 3.0

<#-----------------------------------------------------------------------------
DNS Utility Function Library
Mr. Ashley McGlone
Microsoft Premier Field Engineer
July 2014
http://aka.ms/GoateePFE

Requires an OS:
 Windows Server 2012 and above
 Windows 8.0 and above with RSAT
Requires DNSServer module

-------------------------------------------------------------------------------
LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
 
This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at http://www.microsoft.com/info/cpyright.htm.
-----------------------------------------------------------------------------#>

#requires -modules DNSServer

###############################################################################

Function Backup-DNSServerZoneAll {
param($ComputerName)

    # Before backing up the file we need to flush changes in memory to the file.
    # GUI - Right click zone / Update server data file
    # Use "dnscmd /writebackfiles" to flush all zones to disk.
    # Use "dnscmd /zonewriteback" to flush a single zone to disk.
    Dnscmd $ComputerName /writebackfiles

    $Zones = Get-DnsServerZone -ComputerName $ComputerName |
        Where-Object {$_.ZoneType -eq 'Primary' -and $_.IsAutoCreated -eq $false} |
        Select-Object -ExpandProperty ZoneName

    ForEach ($Zone in $Zones) {
        $Zone

        # Make a backup copy of the CONTOSO.com.dns zone file
        Dnscmd $ComputerName /ZoneExport $Zone $($Zone + "_backup_$(Get-Date -UFormat %Y%m%d%H%M%S).dns")

        # Dump a CSV report of all records for archive and TTL documentation.
        $ZoneRecords = Get-WMIObject -ComputerName $ComputerName `
                -Namespace root\MicrosoftDNS -Class MicrosoftDNS_ResourceRecord `
                -Filter "DomainName='$Zone'"

        $ZoneRecords | 
            Select-Object ContainerName, DnsServerName, DomainName, IPAddress, `
                OwnerName, RecordClass, RecordData, TextRepresentation, `
                Timestamp, TTL | 
            Export-CSV "$($Zone)_backup_$(Get-Date -UFormat %Y%m%d%H%M%S).csv" -NoTypeInformation

    }

    # Verify backup files exists
    Get-ChildItem -Path "\\$ComputerName\admin$\system32\dns\"
}

# For every DNS zone on the specified ComputerName:
# 1. Run "DNSCMD /ZoneExport"
# 2. Dump a CSV file of all records using WMI
#
# Backup-DNSServerZoneAll -ComputerName dc1.contoso.com

###############################################################################

Function Export-DNSServerIPConfiguration {
param($Domain)

    # Get the DNS configuration of each child DC
    $DNSReport = @()

    ForEach ($DomainEach in $Domain) {
        # Get a list of DCs without using AD Web Service
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {

            # Forwarders
            $dnsFwd = Get-WMIObject -ComputerName $("$dc.$DomainEach") `
                -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Server `
                -ErrorAction SilentlyContinue

            # Primary/Secondary (Self/Partner)
            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa393295(v=vs.85).aspx
            $nic = Get-WMIObject -ComputerName $("$dc.$DomainEach") -Query `
                "Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE" `
                -ErrorAction SilentlyContinue

            $DNSReport += 1 | Select-Object `
                @{name="DC";expression={$dc}}, `
                @{name="Domain";expression={$DomainEach}}, `
                @{name="DNSHostName";expression={$nic.DNSHostName}}, `
                @{name="IPAddress";expression={$nic.IPAddress}}, `
                @{name="DNSServerAddresses";expression={$dnsFwd.ServerAddresses}}, `
                @{name="DNSServerSearchOrder";expression={$nic.DNSServerSearchOrder}}, `
                @{name="Forwarders";expression={$dnsFwd.Forwarders}}, `
                @{name="BootMethod";expression={$dnsFwd.BootMethod}}, `
                @{name="ScavengingInterval";expression={$dnsFwd.ScavengingInterval}}

        } # End ForEach

    }

    $DNSReport | Format-Table -AutoSize -Wrap
    $DNSReport | Export-CSV ".\DC_DNS_IP_Report_$(Get-Date -UFormat %Y%m%d%H%M%S).csv" -NoTypeInformation

    "Report file:"
    Get-ChildItem "DC_DNS_IP_Report_*.csv"
}

# Enumerate all DCs in each domain supplied
# For each DC collect all relevant DNS server and client IP configuration information
# Uses NETDOM to query a list of domain controllers in case you are targeting a legacy environment
#
# Export-DNSServerIPConfiguration -Domain 'contoso.com','na.contoso.com','eu.contoso.com'


###############################################################################

Function Export-DNSServerZoneReport {
param($Domain)

    # This report assumes that all DCs are running DNS.
    $Report = @()

    ForEach ($DomainEach in $Domain) {
        # Get a list of DCs without using AD Web Service
        # You may see RiverBed devices returned in this list.
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {

            $DCZones = $null
            Try {
                $DCZones = Get-DnsServerZone -ComputerName $("$dc.$DomainEach") |
                    Select-Object @{Name="Domain";Expression={$DomainEach}}, @{Name="Server";Expression={$("$dc.$DomainEach")}}, ZoneName, ZoneType, DynamicUpdate, IsAutoCreated, IsDsIntegrated, IsReverseLookupZone, ReplicationScope, DirectoryPartitionName, MasterServers, NotifyServers, SecondaryServers

                ForEach ($Zone in $DCZones) {
                    If ($Zone.ZoneType -eq 'Primary') {
                        $ZoneAging = Get-DnsServerZoneAging -ComputerName $("$dc.$DomainEach") -ZoneName $Zone.ZoneName |
                            Select-Object ZoneName, AgingEnabled, NoRefreshInterval, RefreshInterval, ScavengeServers
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $ZoneAging.AgingEnabled
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $ZoneAging.NoRefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $ZoneAging.RefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $ZoneAging.ScavengeServers
                    } Else {
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $null
                    }
                }

            $Report += $DCZones
        } Catch {
            Write-Warning "Error connecting to $dc.$DomainEach."
        }

        } # End ForEach

    }

    $Report | Export-CSV -Path ".\DNS_Zones_$(Get-Date -UFormat %Y%m%d%H%M%S).csv" -NoTypeInformation -Force -Confirm:$false

    "Report file(s):"
    Get-ChildItem "DNS_Zones_*.csv"

}

# Enumerate all DCs in each domain supplied
# For each DC collect all DNS zones hosted on that server
# Export a CSV file of all data
# Uses NETDOM to query a list of domain controllers in case you are targeting a legacy environment
#
# Export-DNSServerZoneReport -Domain 'contoso.com','na.contoso.com','eu.contoso.com'


###############################################################################

Function Add-DNSZoneReverseWithAging {
param([string[]]$Zone,$ComputerName)

    ForEach ($ZoneName in $Zone) {
        Add-DnsServerPrimaryZone -DynamicUpdate NonsecureAndSecure -Name $ZoneName -ZoneFile "$ZoneName.dns" -ComputerName $ComputerName
        Set-DnsServerZoneAging -Name $ZoneName -Aging $true -RefreshInterval (New-TimeSpan -Days 7) -NoRefreshInterval (New-TimeSpan -Days 7) -ComputerName $ComputerName
    }

}

# Create standard primary (text file) zones for the new top-level zones
#
# Add-DNSZoneReverseWithAging -ComputerName localhost -Zone '10.in-addr.arpa','172.in-addr.arpa','192.in-addr.arpa'


###############################################################################



<#
.SYNOPSIS
Copies DNS records from one zone to another.
.DESCRIPTION
This script is designed for situations where you find two primary copies of a
DNS zone and need to copy records from one zone into the other so that you
have a single copy of all the primary zone data in one location.  It works for
both forward and reverse zone.
IMPORTANT: The source zone must be the same level or below the destination
zone.  You cannot copy a parent zone into a child zone.
OK:      subzone.domain.com  -->  domain.com
OK:      domain.com  -->  domain.com
NOT OK:  domain.com  -->  subzone.domain.com
OK:      9.10.in-addr.arpa  -->  10.in-addr.arpa
OK:      10.in-addr.arpa  -->  10.in-addr.arpa
NOT OK:  10.in-addr.arpa  -->  9.10.in-addr.arpa
.PARAMETER SrcServer
Source DNS server
.PARAMETER SrcZone
Records from this zone will be copied into the destination zone
.PARAMETER DestServer
Destination DNS server
.PARAMETER DestZone
Records from the source zone will be copied into this zone
.PARAMETER StaleDays
Dynamic records older than this many days will not be added to the new zone.
Default value is 30 days.
.NOTES
REQUIREMENTS
1.  This script was tested running on Windows Server 2012 (PowerShell v3)
    against a Windows Server 2003 SP2 DC/DNS and against Windows Server 2012.
2.  You must have DNS admin and WMI permissions on the servers involved.
3.  The destination zone must exist (ie. It will not create a new destination
    zone automatically.)
CAVEATS
1.  Permissions on secure DNS record ACLs will be reset.
2.  Records with aging newer than the StaleDays parameter will have their
    timestamp updated to the current date and time. Records with aging
    older than StaleDays will not be copied.
3.  Currently the script supports record types A, CNAME, MX, SRV, PTR.
    Feel free to modify the script for other record types as needed.
4.  The script does not copy delegated sub-domains within a zone.
5.  Delegated subdomains will cause an error if you try to copy a record
    into that subdomain.  Therefore the script will delete any relevant
    delegated subdomains in the destination zone prior to the copy.
.EXAMPLE
Forward zone:
Copy-DNSServerZone -SrcServer dns1.contoso.com -SrcZone myzone.com -DestServer dns2.contoso.com -DestZone myzone.com -StaleDays 14
.EXAMPLE
Reverse zone:
Copy-DNSServerZone -SrcServer dns1.contoso.com -SrcZone 1.10.in-addr.arpa -DestServer dns2.contoso.com -DestZone 1.10.in-addr.arpa -StaleDays 14
.EXAMPLE
Reverse zone roll up:
Copy-DNSServerZone -SrcServer dns1.contoso.com -SrcZone 1.10.in-addr.arpa -DestServer dns2.contoso.com -DestZone 10.in-addr.arpa -StaleDays 14
Copy-DNSServerZone -SrcServer dns1.contoso.com -SrcZone 2.10.in-addr.arpa -DestServer dns2.contoso.com -DestZone 10.in-addr.arpa -StaleDays 14
Copy-DNSServerZone -SrcServer dns1.contoso.com -SrcZone 3.10.in-addr.arpa -DestServer dns2.contoso.com -DestZone 10.in-addr.arpa -StaleDays 14
.LINK
http://aka.ms/GoateePFE
#>
Function Copy-DNSServerZone {
Param (
    [Parameter(Mandatory=$true)]
    $SrcServer,
    [Parameter(Mandatory=$true)]
    $SrcZone,
    [Parameter(Mandatory=$true)]
    $DestServer,
    [Parameter(Mandatory=$true)]
    $DestZone,
    $StaleDays = 21
)

    # Calculate the new record name under the new destination zone.
    $src = Get-DnsServerResourceRecord -ComputerName $SrcServer -ZoneName $srcZone |
        Where-Object {$_.RecordType -ne 'NS' -and $_.RecordType -ne 'SOA'} |
        Select-Object @{name='Name';expression={If ($DestZone -eq $SrcZone) {$_.HostName} Else {"$($_.HostName).$($srcZone.Replace(".$DestZone",$null))"}}}, HostName, TimeStamp, RecordData, RecordType

    # Remove any delegations to the sub zone to be copied in, otherwise there will be an error.
    # We assume that this is a child zone being copied up into a parent zone.
    If ($SrcZone -ne $DestZone) {
        Try {
            Remove-DnsServerZoneDelegation -ComputerName $DestServer -Name $DestZone -ChildZoneName $SrcZone.Replace(".$DestZone",$null) -Force -PassThru -Verbose
        } Catch {
            Write-Warning "No delegation to delete for $($SrcZone.Replace(".$DestZone",$null))."
        }
    }

    # Bug in PSv2 will run a ForEach loop when the collection is NULL
    If (!$src) {
        Write-Warning "No records for zone $srcZone on server $srcServer."
    }
    Else {
        ForEach ($srcRec in $src) {

            # Echo the source record data for logging
            $srcRec

            Switch ($srcRec.RecordType) {

                'PTR' {

                    If ($srcRec.TimeStamp -eq $null) {
                        Add-DnsServerResourceRecord -Name $srcRec.Name -Ptr -ZoneName $destZone -AllowUpdateAny -PtrDomainName $srcRec.RecordData.PtrDomainName -ComputerName $DestServer
                    } Else {
                        If ((New-TimeSpan $srcRec.TimeStamp).TotalDays -gt $StaleDays) {
                            Write-Warning "Skipping stale record add: $($srcRec.Name)"
                        } Else {
                            # Add the entry with fresh aging
                            Add-DnsServerResourceRecord -Name $srcRec.Name -Ptr -ZoneName $destZone -AllowUpdateAny -PtrDomainName $srcRec.RecordData.PtrDomainName -ComputerName $DestServer -AgeRecord
                        }
                    } # End If

                }

                'A' {

                    If ($srcRec.TimeStamp -eq $null) {
                        Add-DnsServerResourceRecord -Name $srcRec.Name -A -ZoneName $destZone -AllowUpdateAny -IPv4Address $srcRec.RecordData.IPv4Address -ComputerName $DestServer
                    } Else {
                        If ((New-TimeSpan $srcRec.TimeStamp).TotalDays -gt $StaleDays) {
                            Write-Warning "Skipping stale record add: $($srcRec.Name)"
                        } Else {
                            # Add the entry with fresh aging
                            Add-DnsServerResourceRecord -Name $srcRec.Name -A -ZoneName $destZone -AllowUpdateAny -IPv4Address $srcRec.RecordData.IPv4Address -ComputerName $DestServer -AgeRecord
                        }
                    } # End If

                }

                'SRV' {

                    If ($srcRec.TimeStamp -eq $null) {
                        Add-DnsServerResourceRecord -Name $srcRec.Name -SRV -ZoneName $destZone -AllowUpdateAny -DomainName $srcRec.RecordData.DomainName -Port $srcRec.RecordData.Port -Priority $srcRec.RecordData.Priority -Weight $srcRec.RecordData.Weight -ComputerName $DestServer
                    } Else {
                        If ((New-TimeSpan $srcRec.TimeStamp).TotalDays -gt $StaleDays) {
                            Write-Warning "Skipping stale record add: $($srcRec.Name)"
                        } Else {
                            # Add the entry with fresh aging
                            Add-DnsServerResourceRecord -Name $srcRec.Name -SRV -ZoneName $destZone -AllowUpdateAny -DomainName $srcRec.RecordData.DomainName -Port $srcRec.RecordData.Port -Priority $srcRec.RecordData.Priority -Weight $srcRec.RecordData.Weight -ComputerName $DestServer -AgeRecord
                        }
                    } # End If

                }

                'CNAME' {

                    If ($srcRec.TimeStamp -eq $null) {
                        Add-DnsServerResourceRecord -Name $srcRec.Name -CName -HostNameAlias $srcRec.RecordData.HostNameAlias -ZoneName $destZone -AllowUpdateAny -ComputerName $DestServer
                    } Else {
                        If ((New-TimeSpan $srcRec.TimeStamp).TotalDays -gt $StaleDays) {
                            Write-Warning "Skipping stale record add: $($srcRec.Name)"
                        } Else {
                            # Add the entry with fresh aging
                            Add-DnsServerResourceRecord -Name $srcRec.Name -CName -HostNameAlias $srcRec.RecordData.HostNameAlias -ZoneName $destZone -AllowUpdateAny -ComputerName $DestServer -AgeRecord
                        }
                    } # End If

                }

                'MX' {

                    If ($srcRec.TimeStamp -eq $null) {
                        Add-DnsServerResourceRecord -Name $srcRec.Name -MX -MailExchange $srcRec.RecordData.MailExchange -Preference $srcRec.RecordData.Preference -ZoneName $destZone -AllowUpdateAny -ComputerName $DestServer
                    } Else {
                        If ((New-TimeSpan $srcRec.TimeStamp).TotalDays -gt $StaleDays) {
                            Write-Warning "Skipping stale record add: $($srcRec.Name)"
                        } Else {
                            # Add the entry with fresh aging
                            Add-DnsServerResourceRecord -Name $srcRec.Name -MX -MailExchange $srcRec.RecordData.MailExchange -Preference $srcRec.RecordData.Preference -ZoneName $destZone -AllowUpdateAny -ComputerName $DestServer -AgeRecord
                        }
                    } # End If

                }

            } #end Switch class

        } #end ForEach source record
    } #end If src

}


Function Copy-DNSZoneReverse {
param($SrcServer,$DestServer)

    $Zones = Get-DnsServerZone -ComputerName $SrcServer |
        Where-Object {$_.ZoneType -eq 'Primary' -and $_.IsAutoCreated -eq $false -and $_.IsReverseLookupZone -eq $true} |
        Select-Object -ExpandProperty ZoneName |
        Select-Object @{name='SrcZone';expression={$_}}, @{name='DestZone';expression={$_.Split('.')[-3..-1] -Join '.'}} | 
        Sort-Object DestZone, SrcZone

    ForEach ($Zone in $Zones) {
        # If consolidating zones all on one server (src and dest), then do not copy the top-level reverse zones back into themselves.
        If (($SrcServer -eq $DestServer) -and ($Zone.srcZone.Split('.').Count -eq 3)) {
            "`n`n- - - - - - - - - - -`n$Zone"
            Write-Warning "Skipping zone to avoid duplication when SrcServer and DestServer are same."
        } Else {
            "`n`n- - - - - - - - - - -`n$Zone"
            Copy-DNSServerZone -SrcServer $SrcServer -SrcZone $Zone.SrcZone -DestServer $DestServer -DestZone $Zone.DestZone -StaleDays 21 | Out-Host
        }
    }

}


Function Remove-DNSZoneReverse {
param($Server)

    # Get all of the reverse zones except the top-level consolidated zones
    $Zones = Get-DnsServerZone -ComputerName $Server |
        Where-Object {$_.ZoneType -eq 'Primary' -and $_.IsAutoCreated -eq $false -and $_.IsReverseLookupZone -eq $true} |
        Select-Object -ExpandProperty ZoneName |
        Select-Object @{name='SrcZone';expression={$_}}, @{name='DestZone';expression={$_.Split('.')[-3..-1] -Join '.'}} | 
        Sort-Object DestZone, SrcZone |
        Where-Object {$_.srcZone.Split('.').Count -gt 3}

    ForEach ($Zone in $Zones) {
        "`n$($Zone.SrcZone)"
        Remove-DnsServerZone -Name $Zone.SrcZone -ComputerName $Server -Confirm:$true
    }

}


# Log all console output
#Start-Transcript .\ReverseDNS.txt

# Dot source to import the DNS functions
#. .\DNSFunctions.ps1

# Example: Copy a single zone
#Copy-DNSZone -SrcServer dc1.contoso.com -SrcZone "1.5.10.in-addr.arpa" `
#    -DestServer dc1.contoso.com -DestZone "10.in-addr.arpa" `
#    -StaleDays 21

# Example: Roll up all reverse zones
#Copy-DNSZoneReverse -SrcServer dc1.contoso.com -DestServer dc2.contoso.com

# Allow time for replication if needed
# Verify that the consolidated zones look good
# Troubleshoot any errors

# Example: Remove all but the top-level reverse zones
#Remove-DNSZoneReverse -Server dc2.contoso.com

# Save the log
#Stop-Transcript

###############################################################################
