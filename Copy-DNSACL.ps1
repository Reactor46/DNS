<#
.NOTES
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages.

.SYNOPSIS
Copy the ACL of the source DN to the target DN recursively

.DESCRIPTION
The goal of this script is to help implementing KB255248:
"How To Create a Target Domain in Active Directory and Delegate the DNS Namespace to the Target Domain"
This script permits copying ACL from the "old" DNS Zone to the DNS records in the new DNZ zone.

.EXAMPLE
 .\Copy-DNSACL.ps1 -SourceZoneDN "DC=contoso.com,CN=MicrosoftDNS,DC=DomainDnsZones,DC=contoso,DC=com" -TargetZoneDN "DC=child.contoso.com,CN=MicrosoftDNS,DC=DomainDnsZones,DC=contoso,DC=com" -TargetDNSZoneShortName "child"
#>

param(
    [string]$SourceZoneDN="",
    [string]$TargetZoneDN="",
    [string]$TargetDNSZoneShortName=""
)

Import-Module ActiveDirectory

if([string]::IsNullOrEmpty($SourceZoneDN))
{
    $SourceZoneDN = Read-Host "Please type the DN of the source DNS Zone (ex: DC=contoso.com,CN=MicrosoftDNS,DC=DomainDnsZones,DC=contoso,DC=com)"
}
if(!(Test-Path "AD:\$SourceZoneDN"))
{
    Write-Error "The specified source DN is invalid: $SourceZoneDN" -ErrorAction "Stop"
}

if([string]::IsNullOrEmpty($TargetZoneDN))
{
    $TargetZoneDN = Read-Host "Please type the DN of the target DNS Zone (ex: DC=Target.contoso.com,CN=MicrosoftDNS,DC=DomainDnsZones,DC=contoso,DC=com)"
}
if(!(Test-Path "AD:\$TargetZoneDN"))
{
    Write-Error "The specified target DN is invalid: $TargetZoneDN" -ErrorAction "Stop"
}

if([string]::IsNullOrEmpty($TargetDNSZoneShortName))
{
    $TargetDNSZoneShortName = Read-Host "Please type the short name of the target DNS Zone (ex: Target)"
}

Write-Output "Counting ACL objects..."
$TargetDNSRoot = [ADSI]"LDAP://$TargetZoneDN"
$nbACLobjects = 1 #starting at 1 for counting Root ACL
Foreach ($TargetDNSEntry in ($TargetDNSRoot.psbase.children))
{
    if ([string]($TargetDNSEntry.distinguishedName) -match "^DC=(?<RecordName>.+),DC=(?<DNSZoneName>.+),CN=MicrosoftDNS,(?<DomainDN>.+)$")
    {
        if($Matches.RecordName -notlike "..SerialNo*" -and $Matches.RecordName -ne "@")#The ..SerialNo and @ objects are ignored
        {
            $nbACLobjects++
        }
    }
}
Write-Output "$nbACLobjects ACL objects found."

Write-Output "Copy the root ACL..."
Set-Acl -AclObject (Get-Acl ("AD:\" + $SourceZoneDN)) -Path ("AD:\" + $TargetZoneDN)

Write-Output "Copy each records' ACL..."
$TargetDNSRoot = [ADSI]"LDAP://$TargetZoneDN"
$nbACLcopied = 1
Foreach ($TargetDNSEntry in ($TargetDNSRoot.psbase.children))
{
    if ([string]($TargetDNSEntry.distinguishedName) -match "^DC=(?<RecordName>.+),DC=(?<DNSZoneName>.+),CN=MicrosoftDNS,(?<DomainDN>.+)$")
    {
        $TargetRecordName = $Matches.RecordName
        $TargetDNSZoneName = $Matches.DNSZoneName

        if($TargetRecordName -notlike "..SerialNo*" -and $TargetRecordName -ne "@")#The ..SerialNo and @ objects are ignored
        {
            Write-Progress -PercentComplete (($nbACLcopied/$nbACLobjects)*100) -Activity "Copying ACL..." -Status "Copy ACL $nbACLcopied on $($nbACLobjects)"

            $SourceRecordName = $TargetRecordName + "." + $TargetDNSZoneShortName #Record -> Record.child
            $SourceDNSZoneName = $TargetDNSZoneName.Replace("$TargetDNSZoneShortName.","") #child.contoso.com -> contoso.com
            
            $SourceDNSEntry = "DC=" + $SourceRecordName + "," + $SourceZoneDN
            $ACL = Get-Acl "AD:\$SourceDNSEntry"
            Set-Acl -AclObject $ACL -Path ("AD:\" + $TargetDNSEntry.distinguishedName)
            $nbACLcopied++
        }
    }
    else
    {
        Write-Error "Unable to parse object: $($TargetDNSEntry.distinguishedName)"
    }
}
Write-Output "$nbACLcopied ACL have been copied."
Write-Output "Done."
