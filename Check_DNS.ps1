## Check_DNS.ps1
## Version 0.3
## Auxilium Technology AS, May 2014
## http://www.auxilium.no
##
## Sometimes, in some projects, you'll deploy a lot of 
## servers and a good practice is to make a DNS record, 
## eighter they are created dynamically or you have to 
## punch them manually.  It's time consuming doing
## a manual nslookup for checking if a DNS record exists
## and are registered correctly!
##
## This script use your local defined DNS server for lookup,
## and a comma separated textfile with IP, FQDN.
##
## The comma separated file needs a header like this "IP";"FQDN"
##


## Check for arguments typed in command line. 
if(!($args[0]))
{
	write-host -Fore Red "** Argument missing! ***"
	write-host ""
	write-host -Fore Red "Usage: .\Check_DNS.ps1 dns_records.csv "
	write-host ""
	exit
}

$computers = import-csv $args[0] -delimiter ";"
$test = $false

foreach ($computer in $computers)
{
	write-host -NoNewLine "Verifying" $computer.FQDN " ... "
	
	## Test if the DNS record exists or not
	try
	{  
		$dnscheck = [System.Net.DNS]::GetHostByName($computer.FQDN)
		$test = $true
	}  
	catch
	{
		write-host -Fore red " <- Failed !"
	}
	
	## Do some verification if DNS record exists
	if($test)
	{
		## Everything OK ?
		if(($dnscheck.HostName -eq $computer.FQDN) -and ($dnscheck.AddressList -eq $computer.IP))
		{
			write-host -Fore Green " -> Success !"
		}
		
		## Check if the alias match too
		if(($dnscheck.Aliases -eq $computer.FQDN) -and ($dnscheck.AddressList -eq $computer.IP))
		{
			write-host -Fore Green " -> Success !"
		}
		
		## Verify that wanted IP match the registered IP
		if(($dnscheck.AddressList -ne $computer.IP) -and ($dnscheck.HostName -eq $computer.FQDN))
		{
			write-host -Fore Yellow " -> Registered IP does not match wanted IP!" 
		}
		
		$test = $false  ## Make sure that this is reset for each loop.
	}	
}