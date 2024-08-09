Param([Parameter(Mandatory=$true)][string]$DNSServers,[Parameter(Mandatory=$true)][string]$DNSHosts)
#Initialize SCOM API
$api = new-object -comObject 'MOM.ScriptAPI'
$bag = $api.CreatePropertyBag()

#Set failure variable to ""
$failure = ""
$errors =0

#Add parameter strings into an array type
[array]$dnsservers = $DNSServers -split ","
[array]$dnshosts = $DNSHosts -split ","

#Don't care if error occurs
$ErrorActionPreference="SilentlyContinue"

#For each DNS server in the array make checks
ForEach ($d in $dnsservers)

{
            #Count the DNS records to check and get each of the records
            For ($i=0; $i -le ($dnshosts.count -1) ;$i++)
            
			    {           
            
			        #Get/Split dns record name and ip out of array dnshosts[0] contains DNS record to check, dnshosts[1] contains IP which record should return
			        $dnspair= $dnshosts[$i].split(":")

                    #Build cmd command NSLOOKUP [Record] [Target DNS] and select the results which start with "Name:"
                    $cmd = "nslookup " + " " + $dnspair[0] + " " + $d

                    #Exceute NSLOOKUP command, convert to string
                    $result=invoke-expression($cmd) | Out-String
                    #Check for the Name: tag in the output
                    $index=$result.IndexOf("Name:")
  
                    #If there is no Name: tag (-1), means there is no record                   
                         If ($index -eq -1)

                            {
                                $value = $false
                            }

                            else

                            {
                                $value= $result.Substring($index) -match  $dnspair[1]

                            }


                    #Check value if is false, means there is something fishy
                        If ($value -eq $false)

                            {    
                                    
							$errors += 1           
                            $failure +=  ("$errors : DNS server " + $d + " does not have host record " + $dnspair[0].ToString() + " which should have IP " + $dnspair[1].ToString() + " or DNS server IP is not valid.`n")                                        
                                                   

                            }


                }


}

If ($errors -ge 1)

	{
		 $bag.AddValue('Result','Bad')
		 $bag.AddValue('Failure',$failure)
	}

If ($errors -eq 0)

	{
		$bag.AddValue('Result','Good')
        $bag.AddValue('Failure','No Errors')

	}

$failure =""
$bag