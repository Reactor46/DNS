Function Get-DNSDebugLog{
<#
.SYNOPSIS
Reads the specified DNS debug log.

.DESCRIPTION
Retrives all entries in the DNS debug log for further processing using powershell or exporting to Excel.

.PARAMETER Path
Specifies the path to the DNS debug logfile.

.PARAMETER Ignore
Specifies which IPs to ignore.

.INPUTS
Takes the filepath of the DNS servers debug log.
And an Ignore parameter to ignore certain ips.

.OUTPUTS
Array of PSCustomObject

\windows\system32\dns\dns.log

.EXAMPLE
Get-DNSDebugLog -Path "$($env:SystemRoot)\system32\dns\dns.log" -Verbose |? {$_.QR -eq "Query"-and $_.Way -eq 'RCV'} |group-Object "Client IP"| Sort-Object -Descending Count| Select -First 10 Name, Count

Name            Count
----            -----
192.168.66.103     21
192.168.66.37      11
192.168.66.22       4
192.168.66.117      1


.EXAMPLE
C:\PS> Import-Module ActiveDirectory
C:\PS> $ignore =  Get-ADDomainController -Filter * | Select-Object -ExpandProperty Hostname |ForEach-Object {[System.Net.Dns]::GetHostAddresses($_)|select -ExpandProperty IPAddressToString}
C:\PS> Get-DNSDebugLog -Ignore:$Ignore -Path '\\dc01.domain.tld\c$\dns.log'

.LINK
Script center: http://gallery.technet.microsoft.com/scriptcenter/Get-DNSDebugLog-Easy-ef048bdf
My Blog: http://virot.eu
Blog Entry: http://virot.eu/wordpress/easy-handling-before-removing-dns/

.NOTES
Author:	Oscar Virot - virot@virot.com
Filename: Get-DNSDebugLog.ps1
#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)]
		[string]
		[ValidateScript({Test-Path($_)})]
		$Path,
		[Parameter(Mandatory=$False)]
		[string[]]
		$Ignore
	)
	Begin
	{
		Write-Verbose "Storing DNS logfile format"
		$dnspattern = "^([0-9]{2,4})-?([0-9]{2})-?([0-9]{2}) ([0-9: ]{8}) ([0-9A-Z]{3,4} PACKET  [0-9A-Za-z]{8,16}) (UDP|TCP) (Snd|Rcv) ([0-9 .]{7,15}) ([0-9a-z]{4}) (.) (.) \[.*\] (.*) (\(.*)"
		Write-Verbose "Storing storing returning customobject format"
		$returnselect = @{label="Client IP";expression={[ipaddress] ($temp[8]).trim()}},
			@{label="DateTime";expression={[DateTime] (Get-Date($temp[1]+'-'+$temp[2]+'-'+$temp[3]+' '+$temp[4]))}},
			@{label="QR";expression={switch($temp[10]){" " {'Query'};"R" {'Response'}}}},
			@{label="OpCode";expression={switch($temp[11]){'Q' {'Standard Query'};'N' {'Notify'};'U' {'Update'};'?' {'Unknown'}}}},
			@{label="Way";expression={$temp[7]}},
			@{label="QueryType";expression={($temp[12]).Trim()}},
			@{label="Query";expression={$temp[13] -replace "(`\(.*)","`$1" -replace "`\(.*?`\)","." -replace "^.",""}}
	}
	Process
	{
		Write-Verbose "Getting the contents of $Path, and matching for correct rows."
		$rows = (Get-Content $Path) -match $dnspattern -notmatch 'ERROR offset' -notmatch 'NOTIMP'
		Write-Verbose "Found $($rows.count) in debuglog, processing 1 at a time."
		ForEach ($row in $rows)
		{
			Try
			{
				$temp = $Null
				$temp = [regex]::split($row,$dnspattern)
				if ($Ignore -notcontains ([ipaddress] ($temp[8]).trim()))
				{
					$true | Select-Object $returnselect
				}
			}
			Catch
			{
				Write-Verbose 'Failed to interpet row.'
				Write-Debug 'Failed to interpet row.'
				Write-Debug $row
			}
		}
	}
	End
	{
	}
}
