#===================================================================
# AD - DNS Server 
#===================================================================

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderDNSS = "heading1"	
Import-Module ActiveDirectory
$addc = Get-ADDomainController -Filter * | select-Object Name
if ($addc -ne $NULL)
{
foreach ($DNSSRVS in $addc){
$DNSSRV = @(get-wmiobject -class "MicrosoftDNS_Zone" -namespace "root\microsoftdns" -comp $DNSSRVS -ErrorAction SilentlyContinue)
if ($DNSSRV -ne $null){
	$DNSN = $DNSSRV.Name
	$DNSDI = $DNSSRV.dsintegrated
	$DNSZT = $DNSSRV.zonetype
	$DNSR = $DNSSRV.reverse
	$DNSAU = $DNSSRV.allowupdate
	$DNSSN = $DNSSRV.DnsServerName
	
    $DetailDNSS+=  "				<tr>"	
	$DetailDNSS+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSN)</b></font></td>"
	$DetailDNSS+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSDI)</b></font></td>"
	$DetailDNSS+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSZT)</b></font></td>"
	$DetailDNSS+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSR)</b></font></td>"
	$DetailDNSS+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSAU)</b></font></td>"	
    $DetailDNSS+=  "				</tr>"	

    $DetailDNSS1+=  "				<tr>"	
	$DetailDNSS1+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSN)</b></font></td>"
	$DetailDNSS1+=  "				<td width='20%'><font color='#0030FF'><b>$($DNSSN)</b></font></td>"
	$DetailDNSS1+=  "				<td width='60%'><font color='#0030FF'></b></font></td>"
    $DetailDNSS1+=  "				</tr>"	
}
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDNSS)'>
            <SPAN class=sectionTitle tabIndex=0>DNS Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
	            	  	<th width='20%'>Name</font></th>
	  					<th width='20%'>Dsintegrated</font></th>
	  					<th width='20%'>Zonetype</font></th>	
	  					<th width='20%'>Reverse</font></th>
	  					<th width='20%'>AllowUpdate</font></th>						
 		   		</tr>
                    $($DetailDNSS)
                </table>
                <table>
	  			<tr>
	            	  	<br><th width='20%'>Name</font></th>
	  					<th width='20%'>DnsServerName</font></th>
	  					<th width='60%'></font></th>	
 		   		</tr>
                    $($DetailDNSS1)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>                
"@
}
else
{
$Report += @"
	</TABLE>
	<div>
    <div>
    <div class='container'>
        <div class='$($ClassHeaderDNSS)'>
            <SPAN class=sectionTitle tabIndex=0>DNS Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
						
 		   		</tr>
                    No DNS Server(s) found in the Organization.						
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>                
"@
}
Return $Report