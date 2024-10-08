#Windows PowerShellCopy Code###########################################################################
#
# NAME: ServerIPs.ps1
#
# AUTHOR: John Grenfell
#
# COMMENT: Forward_Reverse_DNS_Check
#
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.3 26.09.2010 - Beta release
#
#
###########################################################################

Import-Module ActiveDirectory

$ScriptName = "Forward_Reverse_DNS_Check4.txt"
$ScriptPath = "\\server\groups\it\stations"

$Log = "$ScriptPath\$ScriptName"
$DataLog = "$ScriptPath\DATA_$ScriptName"
$ErrorLog = "$ScriptPath\Error_$ScriptName"


$Computers = (Get-ADComputer -LDAPFilter "(name=*)" -SearchBase "OU=Stations,DC=YOURDOMAIN,DC=com" | Select Name | Sort-Object Name)

Function Find-Address(){
Param($LookupType = "ekkkkkk",$ComputerOrIP)

      trap [Exception] { 
      write-host "Can't lookup for $ComputerOrIP" -ForegroundColor Red
      write-output "Can't lookup for $ComputerOrIP" | out-file $ErrorLog -append
      continue}

    $Global:Details = ""
    Write-Host "Lookup $LookupType for $ComputerOrIP"
    
    If ($LookupType -eq "Forward"){
        $Global:Details = @([System.Net.Dns]::GetHostAddresses("$ComputerOrIP"))
        }
    ElseIf ($LookupType -eq "Reverse"){
        $Global:Details = @([System.Net.Dns]::GetHostByAddress("$ComputerOrIP").HostName)
        }

    If ($Details.count -gt "0"){
        Write-Host "Lookup $LookupType for $ComputerOrIP >> $Details" -ForegroundColor GREEN
        Write-output "$ComputerOrIP,$Global:Details" | out-file $Log -append                           
        }
    Else {
        Write-Host "Lookup $LookupType for $ComputerOrIP >> No IP Found" -ForegroundColor RED
        Write-output "$ComputerOrIP,No IP Found" | out-file $Log -append
    }   

}

ForEach ($Computer in $Computers){

      trap [Exception] { 
      write-host "Trapped $Computer" -ForegroundColor Red
      write-output "Errored on $Computer" | out-file $ErrorLog -append
      continue}
    #Empty var

    Find-Address Forward $Computer.name
    $ForwardResults = $Global:Details[0].IPAddressToString
    Find-Address Reverse $Global:Details
    
    #I really wish I knew how to manipulate data types!
    $ReverseResults = $Global:Details
    $ShortResult = $Global:Details[0].ToString()
    $ShortResult = $ShortResult.Substring(0,($ShortResult.IndexOf(".")))
    
    If ($Computer.name -ne $ShortResult){
        Write-Host "Lookup for"$Computer.name "for $ForwardResults ######## NO MATCH" -ForegroundColor DarkRED
        Write-output "$Computer.name,$ForwardResults,$ReverseResults" | out-file $DataLog -append 
    }
    
    #Find-Address Forward COMPUTERNAME
    #Find-Address Reverse IPADDRESS



}