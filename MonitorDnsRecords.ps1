#############################################################################
#       Author: Vikas Sukhija
#       Reviewer:    
#       Date: 01/13/2015
#       Records: MX, A, PTR, SPF
#       Description: Monitor/report critical DNS records
#############################################################################
#########################Variables####################################

$dom = "labtest.com"  #### your domain
$dnss = "8.8.8.8"  #### public dns server

$mx1 = "preference = 10, mail exchanger = email1.labtest.com"  #for comparing mx
$mx2 = "preference = 10, mail exchanger = email2.labtest.com"  #for comparing mx

$a1 = "email1.labtest.com"  #Actual A record
$a2 = "email2.labtest.com"  #Actual A record

$a1c = "Address:  w.x.y.z1"  #for comparing A record
$a2c = "Address:  w.x.y.z2"  #for comparing A record

$r1 = "w.x.y.z1"  #for rev records
$r2 = "w.x.y.z2"  #for rev records 
$r3 = "w.x.y.z3"  #for rev records
$r4 = "w.x.y.z4" #for rev records

$r1c = "Address:  w.x.y.z1"   #for rev record comparison
$r2c = "Address:  w.x.y.z2"   #for rev record comparison
$r3c = "Address:  w.x.y.z3"   #for rev record comparison
$r4c = "Address:  w.x.y.z4"  #for rev record comparison

$spf = "spf1 ip4:w.x.y.z1 ip4:w.x.y.z2"  #for spf comparison


$reportpath = ".\DnsReport.htm" 

if((test-path $reportpath) -like $false)
{
new-item $reportpath -type file
}
$smtphost = "smtp.labtest.com" 
$from = "DoNotReply@labtest.com 
$email1 = "VikasSukhija@labtest.com"


###############################HTml Report Content############################
$report = $reportpath

Clear-Content $report 
Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>Exchange Status Report</title>' 
add-content $report '<STYLE TYPE="text/css">' 
add-content $report  "<!--" 
add-content $report  "td {" 
add-content $report  "font-family: Tahoma;" 
add-content $report  "font-size: 11px;" 
add-content $report  "border-top: 1px solid #999999;" 
add-content $report  "border-right: 1px solid #999999;" 
add-content $report  "border-bottom: 1px solid #999999;" 
add-content $report  "border-left: 1px solid #999999;" 
add-content $report  "padding-top: 0px;" 
add-content $report  "padding-right: 0px;" 
add-content $report  "padding-bottom: 0px;" 
add-content $report  "padding-left: 0px;" 
add-content $report  "}" 
add-content $report  "body {" 
add-content $report  "margin-left: 5px;" 
add-content $report  "margin-top: 5px;" 
add-content $report  "margin-right: 0px;" 
add-content $report  "margin-bottom: 10px;" 
add-content $report  "" 
add-content $report  "table {" 
add-content $report  "border: thin solid #000000;" 
add-content $report  "}" 
add-content $report  "-->" 
add-content $report  "</style>" 
Add-Content $report "</head>" 
Add-Content $report "<body>" 
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>MX Record test</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
 
add-content $report  "<table width='100%'>" 
Add-Content $report  "<tr bgcolor='IndianRed'>" 
Add-Content $report  "<td width='25%' align='center'><B>Domain</B></td>" 
Add-Content $report  "<td width='25%' align='center'><B>MXStatus</B></td>" 
 
Add-Content $report "</tr>" 

#####################################test MX records#################################
add-type -AssemblyName microsoft.visualbasic 
$cmp = "microsoft.visualbasic.strings" -as [type]
$mxlookup=nslookup  -querytype=mx $dom $dnss

Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $dom</B></td>" 

if(($cmp::instr($mxlookup, $mx1)) -and ($cmp::instr($mxlookup, $mx2)))
{
                  Write-Host $dom `t Mxlookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>MXTestPassed</B></td>"
}
else
{
		   Write-Host $dom `t Mxlookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>MXTestfailed</B></td>"
}

Add-Content $report "</tr>"
########################################################################################
#####################################Test A records#####################################

add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>A Records test</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"

add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='25%' align='center'><B>Host Names</B></td>" 
Add-Content $report "<td width='25%' align='center'><B>Status</B></td>" 
Add-Content $report "</tr>" 


add-type -AssemblyName microsoft.visualbasic 
$cmp = "microsoft.visualbasic.strings" -as [type]

	Add-Content $report "<tr>" 
	$Alookup=nslookup  -querytype=A $a1 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $a1 </B></td>" 

	if($cmp::instr($Alookup, $a1c))
	{
                  Write-Host $a1 `t A Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>ArecordTestPassed</B></td>"
	}
	else
	{
		   Write-Host $a1  `t A Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>ARecordTestfailed</B></td>"

	}
	Add-Content $report "</tr>"

	Add-Content $report "<tr>" 
	add-type -AssemblyName microsoft.visualbasic 
	$cmp = "microsoft.visualbasic.strings" -as [type]
	$Alookup=nslookup  -querytype=A $a2 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $a2 </B></td>" 

	if($cmp::instr($Alookup, $a2c))
	{
                  Write-Host $a2  `t A Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>ArecordTestPassed</B></td>"
	}
	else
	{
		   Write-Host $a2 `t A Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>ARecordTestfailed</B></td>"

	}
       Add-Content $report "</tr>"



#########################################################################################
#####################################Test reverseDNS#####################################

add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Reverse DNS test</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"

add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='25%' align='center'><B>Reverse IP</B></td>" 
Add-Content $report "<td width='25%' align='center'><B>Status</B></td>" 
Add-Content $report "</tr>" 

add-type -AssemblyName microsoft.visualbasic 
$cmp = "microsoft.visualbasic.strings" -as [type]

add-type -AssemblyName microsoft.visualbasic 
$cmp = "microsoft.visualbasic.strings" -as [type]

	Add-Content $report "<tr>" 
	$Alookup=nslookup   $r1 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $r1 </B></td>" 

	if($cmp::instr($Alookup, $r1c))
	{
                  Write-Host $r1  `t Revrese Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>RevDNSTestPassed</B></td>"
	}
	else
	{
		   Write-Host $r1 `t Revrese Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>revDNSTestfailed</B></td>"

	}
	Add-Content $report "</tr>"
##############
	Add-Content $report "<tr>" 
	$Alookup=nslookup   $r2 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $r2 </B></td>" 

	if($cmp::instr($Alookup, $r2c))
	{
                  Write-Host $r2  `t Revrese Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>RevDNSTestPassed</B></td>"
	}
	else
	{
		   Write-Host $r2 `t Revrese Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>revDNSTestfailed</B></td>"

	}
	Add-Content $report "</tr>"
#####################
	Add-Content $report "<tr>" 
	$Alookup=nslookup   $r3 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $r3 </B></td>" 

	if($cmp::instr($Alookup, $r3c))
	{
                  Write-Host $r3  `t Revrese Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>RevDNSTestPassed</B></td>"
	}
	else
	{
		   Write-Host $r3`t Revrese Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>revDNSTestfailed</B></td>"

	}
	Add-Content $report "</tr>"
#################
	Add-Content $report "<tr>" 
	$Alookup=nslookup   $r4 $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $r4 </B></td>" 

	if($cmp::instr($Alookup, $r4c))
	{
                  Write-Host $r4 `t Revrese Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>RevDNSTestPassed</B></td>"
	}
	else
	{
		   Write-Host $r4 `t Revrese Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>revDNSTestfailed</B></td>"

	}
	Add-Content $report "</tr>"
#########################
#################################################################################################################
########################################Spf Test#################################################################

add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Spf DNS test</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>"

add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='25%' align='center'><B>Domain</B></td>" 
Add-Content $report "<td width='25%' align='center'><B>SpfTestSattus</B></td>" 
Add-Content $report "</tr>" 

add-type -AssemblyName microsoft.visualbasic 
$cmp = "microsoft.visualbasic.strings" -as [type]

	Add-Content $report "<tr>" 
	$Alookup=nslookup   -type=TXT $dom $dnss

	Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $dom </B></td>" 

	if($cmp::instr($Alookup, $spf))
	{
                  Write-Host $dom `t Spf Lookup Test Passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>SpfDNSTestPassed</B></td>"
	}
	else
	{
		   Write-Host $dom `t Spf Lookup Test failed -ForegroundColor Red
	           Add-Content $report "<td bgcolor= 'Red' align=center><B>SpfDNSTestfailed</B></td>"

	}
	Add-Content $report "</tr>"
############################################Close HTMl Tables###########################


Add-content $report  "</table>" 
Add-Content $report "</body>" 
Add-Content $report "</html>" 

#########################################################################################
#############################################Send Email#################################


$subject = "DNS Record Monitoring" 
$body = Get-Content ".\Dnsreport.htm" 
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost 
$msg = New-Object System.Net.Mail.MailMessage 
$msg.To.Add($email1)
$msg.from = $from
$msg.subject = $subject
$msg.body = $body 
$msg.isBodyhtml = $true 
$smtp.send($msg) 

########################################################################################

########################################################################################








