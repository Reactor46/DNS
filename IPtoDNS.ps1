# The following line read a plain list of IPs from files.  For this demo, I have

# this line commented out and added a line to just define an array of IPs here


 

$listofIPs = Get-Content .\IPList.txt
#$listofIPs = "173.136.234.58","173.136.234.59","173.136.234.60"


 

#Lets create a blank array for the resolved names

$ResultList = @()


 

# Lets resolve each of these addresses

foreach ($ip in $listofIPs)

{

     $result = $null

    

     $currentEAP = $ErrorActionPreference

     $ErrorActionPreference = "silentlycontinue"

    

     #Use the DNS Static .Net class for the reverse lookup

     # details on this method found here: http://msdn.microsoft.com/en-us/library/ms143997.aspx

     $result = [System.Net.Dns]::gethostentry($ip)

    

     $ErrorActionPreference = $currentEAP

    

     If ($Result)

     {

          $Resultlist += [string]$Result.HostName

     }

     Else

     {

          $Resultlist += "$IP - No HostNameFound"

     }

}


 

# If we wanted to output the results to a text file we could do this, for this

# demo I have this line commented and another line here to echo the results to the screen


 

$resultlist | Out-File .\output.txt


 

#$ResultList