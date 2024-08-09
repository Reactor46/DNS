# Variable that contains all authroized DHCP servers the domain
$Servers=Get-DhcpServerInDC

# Defines obj array for use in IF statement
$Obj = @()

# Foreach loop that performs functions against each of the servers piped into $Servers variable
Foreach($Server in $Servers)
{

# Variable that contains the scopes of the server being evaluated in the foreach loop
$Scopes=Get-DHCPServerv4Scope -ComputerName $Server.DnsName

    # Foreach loop that performs functions against each of the scopes piped into $Scopes
    Foreach($Scope in $Scopes)
    {
    
        # IF statement that performs functions on Active scopes
        If($Scope.State -contains "Active")
            {
            # Variable that contains the DNS scope settings
            $DNSInfo=Get-DHCPServerv4DNSSetting -ComputerName $Server.DnsName -ScopeID $Scope.ScopeId.IPAddressToString
            
            # Custom object to place scope values in
            $Object = New-Object -TypeName PSObject
		
            # Adds the desired values gathered from $Server, $Scope, and $DNSInfo into the custom object; comment out those that are not desired.
            $Object|Add-Member -MemberType NoteProperty -Name "Server Name" -Value $Server.DnsName
            $Object|Add-Member -MemberType NoteProperty -Name "Scope Name" -Value $Scope.Name
    	    $Object|Add-Member -MemberType NoteProperty -Name "Perform Dynamcic Updates" -Value $DNSInfo.DynamicUpdates
            $Object|Add-Member -MemberType NoteProperty -Name "Delete Records After Lease" -Value $DNSInfo.DeleteDnsRROnLeaseExpiry
            $Object|Add-Member -MemberType NoteProperty -Name "Update Records Without Request" -Value $DNSInfo.UpdateDnsRRForOlderClients
            $Object|Add-Member -MemberType NoteProperty -Name "Disable PTR Record Update" -Value $DNSInfo.DisableDnsPtrRRUpdate
            $Object|Add-Member -MemberType NoteProperty -Name "Name Protection" -Value $DNSInfo.NameProtection

		    # Stores the values in a variable    
		    $Obj+=$Object
            }
        Else
            {
            # no action take if scope is inactive
            }
    }
}

# Adjust comment marks below to print out to screen instead/also

# Outputs to CSV file
$Obj | Export-Csv -Path "YourDesiredPath"

# Outputs to Screen
#$Obj