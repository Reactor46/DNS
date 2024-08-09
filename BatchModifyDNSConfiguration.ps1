#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 

Param([String[]]$NewDNS,[String]$OldDNS,[String]$OU)
#requires -Version 2

#Adds active directory modules to the current session
Import-Module -Name ActiveDirectory

#region Custom DNS Configure Report

$ScriptPath = ($myinvocation.mycommand.Path).Replace($myinvocation.mycommand.Name,"")
$key = $(Get-Date -format "MMddhhmmss")

#It creates a report file in current script position
New-Item "$ScriptPath\report_$key.html" -ItemType file | Out-Null

$HTML=@"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<style> BODY{font-family:Verdana; background-color:lightblue;}
	TABLE{border-width: 2px;border-style: solid;border-color: black;border-collapse: collapse;} 
	TH{font-size:1.2em; border-width: 2px;padding: 2px;border-style: solid;border-color: black;background-color:lightskyblue} 
	TD{border-width: 2px;padding: 2px;border-style: solid;border-color: black;align=right}
	</style>
</head><body>
<H1>DNS Configuration</H1>
<table>
<colgroup>
<col/>
<col/>
</colgroup>
<tr bgcolor=yellow><th>Computer Name</th><th>Status</th><th>Current_DNS_Address</th><th>Previous_DNS_Address</th></tr>
"@
Add-Content -Value $HTML -path "$ScriptPath\report_$key.html"
#endregion


#region Main Function

#Get full distinguished name
$DistName = Get-ADOrganizationalUnit -Filter 'Name -like $OU' | ForEach-Object{$_.DistinguishedName}
#Retrieve all computer objects in the OU
$Servers = Get-ADComputer -SearchBase "$DistName" -Filter "*" | ForEach-Object {$_.Name}


foreach($Server in $Servers)
{
	#Connecting test
	$PingResult = Test-Connection -ComputerName $Server -Count 1 -Quiet
	if($PingResult)
	{
		#Use the Windows PowerShell to monitor for errors.
		try
		{	
			<#If the computer we are querying is a DHCP client and the DNS servers setting were 
			assigned by a DHCP server option, then do not modify.#>
			$NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Server -ErrorAction Stop | `
			Where-Object {$_.IPEnabled -eq $TRUE -and $_.DHCPEnabled -eq $False}
	
			foreach($NIC in $NICs) 
			{	
				$PreDNSInfo = $NIC | Foreach-Object {if($_.DNSServerSearchOrder -match $OldDNS ){$_.DNSServerSearchOrder}}
				$PreDNSInfo = $PreDNSInfo -join ","
				
				#Set up DNS information
				if($NIC.DNSServerSearchOrder -match $OldDNS )
				{
					$DNSServers = $NewDNS
					$NIC.SetDNSServerSearchOrder($DNSServers) | Out-Null
					$NIC.SetDynamicDNSRegistration("TRUE") | Out-Null
					#Get the DNS information
					
					Write-Host "$Server Setting Successed!" -ForegroundColor Green
					Add-Content -Value "<tr bgcolor=#F0F8FF><td align=left>$server</td><td align=center>Setting Successed</td><td align=center>$($NewDNS -join ",")</td><td align=center>$PreDNSInfo</td></tr>" -Path "$ScriptPath\report_$key.html"
				}
			}
		}
		#When an error occurs within the Try block, triggers an exception.
		catch
		{
			Write-Warning "$Server Setting Failed! $Error[0]"
			Add-Content -Value "<tr bgcolor=#F0F8FF><td align=left>$server</td><td align=center>Setting Failed</td><td align=center> </td><td align=center> </td></tr>" -Path "$ScriptPath\report_$key.html"
		}
	}
	else
	{
		Write-Host "$Server Failed to connect!" -ForegroundColor Yellow
		Add-Content -Value "<tr bgcolor=#F0F8FF><td align=left>$server</td><td align=center>Failed to connect</td><td align=center> </td><td align=center> </td></tr>" -Path "$ScriptPath\report_$key.html"
	}
}
#endregion

#Modify configure report
Add-Content -Value '</table>' -Path "$ScriptPath\report_$key.html"
Add-Content -Value '</body></html>' -Path "$ScriptPath\report_$key.html"
Add-Content -Value "<p>---------- $(get-date) ----------</p>" -Path "$ScriptPath\report_$key.html"

