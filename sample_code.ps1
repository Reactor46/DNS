#requires -version 3.0

# Do not run the entire script by accident
break

# Dot source to import the DNS functions
. .\DNSFunctions.ps1

Backup-DNSServerZoneAll -ComputerName dc1.contoso.com

Export-DNSServerIPConfiguration -Domain 'contoso.com','na.contoso.com','eu.contoso.com'
Export-DNSServerIPConfiguration -Domain 'cohovineyard.com','wingtiptoys.local'

Export-DNSServerZoneReport -Domain 'contoso.com','na.contoso.com','eu.contoso.com'
Export-DNSServerZoneReport -Domain 'cohovineyard.com','wingtiptoys.local'

Add-DNSZoneReverseWithAging -ComputerName localhost -Zone '172.in-addr.arpa','192.in-addr.arpa'

# Example: Copy a single zone
Copy-DNSServerZone -SrcServer dc1.contoso.com -SrcZone "1.5.10.in-addr.arpa" `
    -DestServer dc1.contoso.com -DestZone "10.in-addr.arpa" `
    -StaleDays 21

Get-Help Copy-DNSServerZone -Full

Copy-DNSServerZone -SrcServer localhost -SrcZone "50.10.in-addr.arpa" `
    -DestServer localhost -DestZone "10.in-addr.arpa" `
    -StaleDays 21

# Example: Roll up all reverse zones
Copy-DNSZoneReverse -SrcServer dc1.contoso.com -DestServer dc2.contoso.com
Copy-DNSZoneReverse -SrcServer localhost -DestServer localhost

# Allow time for replication if needed
# Verify that the consolidated zones look good
# Troubleshoot any errors

# Example: Remove all but the top-level reverse zones
Remove-DNSZoneReverse -Server dc2.contoso.com
Remove-DNSZoneReverse -Server localhost


