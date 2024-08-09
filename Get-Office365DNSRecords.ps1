# Get-Office365DNSRecords.ps1 
# Author: Peter Schmidt (www.msdigest.net)
# Last update: 2014.04.11
# Version: 1.1
# 
# This script scans a CSV file for a list of domains and then scans each domain for DNS records that may indicate which Office 365 services is setup in DNS.
# All information is written as detailed output to a text file
# Note: These are public DNS records, this is not getting anything not already published by the domain owner
# Use at your own risk, get the domain providers permission, look both ways before crossing the road.
#
# Example use: Take a list the common domains your company emails and check if any of them may be used with Office 365
#
# It expects a CSV with a single column titled domains
#
# Credits and thanks goes to these guys:
# This script requires PoshNet.dll from http://huddledmasses.org/powershell-dig-nslookup-cmdlet/ - huge credit and thanks for PoshNet to Joel 'Jaykul' Bennett
# This script is inspired from Tom Arbuthnot original Lync DNS script, found at (http://lyncdup.com/2011/11/script-get-lyncdnssrvrecords-ps1-check-a-list-of-domains-for-possible-ocslync-federation/)
#
# Feedback are always welcome, please feedback at www.msdigest.net.

########################
# Variables to set

$domainscsvlist = '.\domainstotest.csv'
$resultstxtfile = '.\results.txt'
$poshnetdll = '.\PoshNet.dll'

##########################

Import-Module $poshnetdll

$domains = Import-Csv $domainscsvlist

foreach ($row in $domains)
	{
	$domaintotest = $row.domain
	$autodiscovercheck = Get-Dns autodiscover.$domaintotest cname | select -ExpandProperty additionals | ft
	$mxcheck = Get-Dns $domaintotest mx | select -ExpandProperty additionals | ft	
	$siptlscheck = Get-Dns _sip._tls.$domaintotest srv | select -ExpandProperty additionals | ft
	$sipfederationtlscheck = Get-Dns _sipfederationtls._tcp.$domaintotest srv | select -ExpandProperty additionals | ft
	$sipcheck = Get-Dns sip.$domaintotest cname | select -ExpandProperty additionals | ft
	$lyncdiscovercheck = Get-Dns lyncdiscover.$domaintotest cname | select -ExpandProperty additionals | ft
	$msoidcheck = Get-Dns msoid.$domaintotest cname | select -ExpandProperty additionals | ft
	
	if ($autodiscovercheck -ne $null)
			{
			Write-host Autodiscover Record found: autodiscover.$domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"_sip._tls.$domaintotest" | Out-File -append .\results.txt
			$autodiscovercheck | Out-File -append .\results.txt			
			}
	else
			{
			Write-Host No autodiscover record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($mxcheck -ne $null)
			{
			Write-host MX Records found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"_sip._tls.$domaintotest" | Out-File -append .\results.txt
			$mxcheck | Out-File -append .\results.txt			
			}
	else
			{
			Write-Host No MX record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($siptlscheck -ne $null)
			{
			Write-host SIP TLS Records found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"_sip._tls.$domaintotest" | Out-File -append .\results.txt
			$siptlscheck | Out-File -append .\results.txt			
			}
	else
			{
			Write-Host No SIP TLS record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($sipfederationtlscheck -ne $null)
			{
			Write-Host SIP Federation TLS Records found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"_sipfederationtls._tcp.$domaintotest" | Out-File -append .\results.txt
			$sipfederationtlscheck | Out-File -append .\results.txt
			}
	else
			{
			Write-Host No SIP Federation TLS record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($sipcheck -ne $null)
			{
			Write-Host SIP Record found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"sip.$domaintotest" | Out-File -append .\results.txt
			$sipcheck | Out-File -append .\results.txt
			}
	else
			{
			Write-Host No SIP record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($lyncdiscovercheck -ne $null)
			{
			Write-Host Lyncdiscover Record found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"lyncdiscover.$domaintotest" | Out-File -append .\results.txt
			$lyncdiscovercheck | Out-File -append .\results.txt
			}
	else
			{
			Write-Host No Lyncdiscover record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	if ($msoidcheck -ne $null)
			{
			Write-Host MSOID Record found for $domaintotest -foregroundcolor green
			$domaintotest | Out-File -append .\results.txt
			"lyncdiscover.$domaintotest" | Out-File -append .\results.txt
			$msoidcheck | Out-File -append .\results.txt
			}
	else
			{
			Write-Host No MSOID record found for $domaintotest -foregroundcolor red -backgroundcolor yellow
			}
	
	$siptlscheck = $null
	$sipfederationtlscheck = $null
	}
Write-Host 'Checks complete'
	
