<#
.Synopsis
   DNS Geek Tool for fixing DNS issues on Windows PCs
#>
[CmdletBinding()]
param()


Begin
{
$ErrorActionPreference="SilentlyContinue"
#region Function Show-Disclaimer 
Function Show-Disclaimer 
{
$disclaimer = @'
DISCLAIMER: DNS Geek Tool is a property of Appuals.com. 
      

       db                                                       88            
      d88b                                                      88            
     d8'`8b                                                     88            
    d8'  `8b     8b,dPPYba,  8b,dPPYba,  88       88 ,adPPYYba, 88 ,adPPYba,  
   d8YaaaaY8b    88P'    "8a 88P'    "8a 88       88 ""     `Y8 88 I8[    ""  
  d8""""""""8b   88       d8 88       d8 88       88 ,adPPPPP88 88  `"Y8ba,   
 d8'        `8b  88b,   ,a8" 88b,   ,a8" "8a,   ,a88 88,    ,88 88 aa    ]8I  
d8'          `8b 88`YbbdP"'  88`YbbdP"'   `"YbbdP'Y8 `"8bbdP"Y8 88 `"YbbdP"'  
                 88          88                                               
                 88          88                                          
'@
Write-Output $disclaimer
}
#region Function Show-Disclaimer 

Function Check-DNSSettings4
{
    param 
    (
        $NetworkAdapter, 
        [string[]]$DNSAddresses = @("LASDC01","LASDC02")
    )

        $DNSConfiguration = Get-DnsClientServerAddress -InterfaceAlias $($NetworkAdapter.Name) -AddressFamily IPv4 

        $diff = Compare-Object -ReferenceObject $DNSAddresses -DifferenceObject $DNSConfiguration.ServerAddresses -ExcludeDifferent -PassThru -IncludeEqual
    
        If (($diff | Measure-Object).Count -eq 2) 
            {return $true}
        else
            {return $false}
}

Function Check-DNSSettings2
{
 param 
    (
        $NetworkAdapter, 
        [string[]]$DNSAddresses = @("8.8.8.8","8.8.4.4")
    )

        $DNSConfiguration = $NetworkAdapter.DNSServerSearchOrder

        $diff = Compare-Object -ReferenceObject $DNSAddresses -DifferenceObject $DNSConfiguration -ExcludeDifferent -PassThru -IncludeEqual
    
        If (($diff | Measure-Object).Count -eq 2) 
            {return $true}
        else
            {return $false}

}


Function Set-DNSSettings4
{
    param 
    (
        $NetworkAdapter, 
        [string[]]$DNSAddresses = @("8.8.8.8","8.8.4.4")
    )

        Set-DnsClientServerAddress -InterfaceIndex $($NetworkAdapter.ifIndex) -ServerAddresses ($DNSAddresses) | Out-Null
        
        If (Check-DNSSettings4 -NetworkAdapter $NetworkAdapter) 
            {return $true}
        else
            {return $false}
}

Function Set-DNSSettings2
{
    param 
    (
        $NetworkAdapter, 
        [string[]]$DNSAddresses = @("8.8.8.8","8.8.4.4")
    )

        $NetworkAdapter.SetDNSServerSearchOrder($DNSAddresses)
        
        If (Check-DNSSettings2 -NetworkAdapter $NetworkAdapter) 
            {return $true}
        else
            {return $false}
}


Function Flush-Cache4
{
    Clear-DnsClientCache -ErrorAction SilentlyContinue
}

Function Flush-Cache2
{
    &"ipconfig.exe" /flushdns | Out-Null
}

Function Check-Site4 
{
    param 
    (
        [string]$Site
    )
    
    Write-Host -Object "Checking `"$($Site)`"..." 
    
    Write-Host -Object "Resolving DNS: `"$($Site)`"..." 
    #LOCAL DNS checking
    Try
        {$local_dns = [Net.dns]::GetHostEntry($Site)}
    catch
        {$local_dns = $false}
    If ($local_dns -ne $false)
    {
        Write-Host "Local DNS Lookup: Valid" -ForegroundColor Green
        $l_dns = $true
    }
    else
    {
        Write-Host "Local DNS Lookup: Failed" -ForegroundColor Red
        $l_dns = $false
    }
    #REMOTE DNS checking
    $dns_uri = "http://check-host.net/check-dns?host=$($site)&max_nodes=1"
    $dns_request = Invoke-WebRequest -Uri $dns_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue
    $dns_json_request = ConvertFrom-Json $dns_request.Content
    $dns_node = ($dns_json_request.nodes | Get-Member)[-1].Name
    Start-Sleep -Seconds 10
    $dns_result_uri = ("http://check-host.net/check-result/", $dns_json_request.request_id -join "")
    $dns_result = (Invoke-WebRequest -Uri $dns_result_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue).Content | ConvertFrom-Json 
    
    If ($dns_result.$dns_node | Where-Object {$_.A -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"} )
    {
        Write-Host "Remote DNS Lookup: Valid" -ForegroundColor Green
        $r_dns = $true
    }
    else
    {
        Write-Host "Remote DNS Lookup: Failed" -ForegroundColor Red
        $r_dns = $false
    }
    
    Write-Host -Object "Checking Local Ping `"$($Site)`"..." 
    If (Test-Connection $Site -ErrorAction SilentlyContinue)
    {
        Write-Host "Local ping: Valid" -ForegroundColor Green
        $l_ping = $true
    }
    else
    {
        Write-Host "Local ping: Failed" -ForegroundColor Red
        $l_ping = $false
    }
    Write-Host -Object "Checking Remote Ping `"$($Site)`"..."
    
    $uri = "http://check-host.net/check-ping?host=$($site)&max_nodes=1"
    $request = Invoke-WebRequest -Uri $uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue
    $json_request = ConvertFrom-Json $request.Content
    $node = ($json_request.nodes | Get-Member)[-1].Name
    #Waiting for remote ping execution
    Start-Sleep -Seconds 10
    $result_uri = ("http://check-host.net/check-result/", $json_request.request_id -join "")
    $result = (Invoke-WebRequest -Uri $result_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue).Content | ConvertFrom-Json
    
    If ($result.$node | Where-Object {$_.SyncRoot -match "OK"} )
    {
        Write-Host "Remote ping: Valid" -ForegroundColor Green
        $r_ping = $true
    }
    else
    {
        Write-Host "Remote ping: Failed" -ForegroundColor Red
        $r_ping = $false
    }
    
    if ($l_dns -and $l_ping -and $r_ping -and $r_dns)
    {
        Write-Host -Object "DNS Geek was able to establish connection to `"$($site)`"" -ForegroundColor Green    
        return $true
    }
    else
    {
        Write-Host -Object "DNS Geek was NOT able to establish connection to `"$($site)`"" -ForegroundColor Red    
        return $false
    }
}

Function Check-Site2
{
    param 
    (
        [string]$Site
    )
    
    Write-Host -Object "Checking `"$($Site)`"..." 
    
    Write-Host -Object "Resolving DNS: `"$($Site)`"..." 
    #LOCAL DNS checking
    Try
        {$local_dns = [Net.dns]::GetHostEntry($Site)}
    catch
        {$local_dns = $false}
    If ($local_dns -ne $false)
    {
        Write-Host "Local DNS Lookup: Valid" -ForegroundColor Green
        $l_dns = $true
    }
    else
    {
        Write-Host "Local DNS Lookup: Failed" -ForegroundColor Red
        $l_dns = $false
    }
    if ($PSVersionTable.PSVersion -gt [Version]"3.0")
    {
        #REMOTE DNS checking
        $dns_uri = "http://check-host.net/check-dns?host=$($site)&max_nodes=1"
        $dns_request = Invoke-WebRequest -Uri $dns_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue
        $dns_json_request = ConvertFrom-Json $dns_request.Content
        $dns_node = ($dns_json_request.nodes | Get-Member)[-1].Name
        Start-Sleep -Seconds 10
        $dns_result_uri = ("http://check-host.net/check-result/", $dns_json_request.request_id -join "")
        $dns_result = (Invoke-WebRequest -Uri $dns_result_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue).Content | ConvertFrom-Json 
        
        If ($dns_result.$dns_node | Where-Object {$_.A -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"} )
        {
            Write-Host "Remote DNS Lookup: Valid" -ForegroundColor Green
            $r_dns = $true
        }
        else
        {
            Write-Host "Remote DNS Lookup: Failed" -ForegroundColor Red
            $r_dns = $false
        }
    } else
        {$ps2 = $true}
    
    Write-Host -Object "Checking Local Ping `"$($Site)`"..." 
    If (Test-Connection $Site -ErrorAction SilentlyContinue)
    {
        Write-Host "Local ping: Valid" -ForegroundColor Green
        $l_ping = $true
    }
    else
    {
        Write-Host "Local ping: Failed" -ForegroundColor Red
        $l_ping = $false
    }
    if ($PSVersionTable.PSVersion -gt [Version]"3.0")
    {
        Write-Host -Object "Checking Remote Ping `"$($Site)`"..."
        $uri = "http://check-host.net/check-ping?host=$($site)&max_nodes=1"
        $request = Invoke-WebRequest -Uri $uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue
        $json_request = ConvertFrom-Json $request.Content
        $node = ($json_request.nodes | Get-Member)[-1].Name
        #Waiting for remote ping execution
        Start-Sleep -Seconds 10
        $result_uri = ("http://check-host.net/check-result/", $json_request.request_id -join "")
        $result = (Invoke-WebRequest -Uri $result_uri -Headers @{"Accept"="application/json"} -ErrorAction SilentlyContinue).Content | ConvertFrom-Json
        
        If ($result.$node | Where-Object {$_.SyncRoot -match "OK"} )
        {
            Write-Host "Remote ping: Valid" -ForegroundColor Green
            $r_ping = $true
        }
        else
        {
            Write-Host "Remote ping: Failed" -ForegroundColor Red
            $r_ping = $false
        }
    } else 
        {$ps2 = $true}
    if (($l_dns -and $l_ping -and $r_ping -and $r_dns) -or ($ps2 -and $l_dns -and $l_ping))
    {
        Write-Host -Object "DNS Geek was able to establish connection to `"$($site)`"" -ForegroundColor Green    
        return $true
    }
    else
    {
        Write-Host -Object "DNS Geek was NOT able to establish connection to `"$($site)`"" -ForegroundColor Red    
        return $false
    }
}
Function Check-HostsFile
{
    $hosts_file = ($env:SystemRoot, "System32", "Drivers", "etc", "Hosts" -join "\")
    $hosts_file_backup = ($env:SystemRoot, "System32", "Drivers", "etc", "Hosts.backup" -join "\")
    $hosts_file_new = ($env:SystemRoot, "System32", "Drivers", "etc", "Hosts.new" -join "\")

    $hosts = Get-Content -Path $hosts_file
    
    foreach ($line in $hosts)
    {
        if (-not [string]::IsNullOrEmpty($line) -and $line -notmatch "^#")
        {
            
            Add-Content -Value "#$($line)" -Path $hosts_file_new
        }
        else
        {
            Add-Content -Value $line -Path $hosts_file_new
        }
    }
    Copy-Item -Path $hosts_file -Destination $hosts_file_backup -Force
    Move-Item -Path $hosts_file_new -Destination $hosts_file -Force
}
function Test-IsAdmin {

([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

}
}
Process
{
#Clear screen
Clear-Host
#Show disclaimer
Show-Disclaimer

#Check if it launched under admin account
If (-not (Test-IsAdmin))
{
    Write-Host -Object "The script should be launched with administrator rights" -ForegroundColor Red
    return   
}

#Checking PS Version
if (($PSVersionTable.PSVersion -gt [Version]"3.0") -and ([Environment]::OSVersion.Version -gt [Version]"6.2"))
{
    #PowerShell Version is 4 or above
    $NetworkAdapters = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}
    #$NetworkAdapters | ft
    Foreach ($NetworkAdapter in $NetworkAdapters)
    {
        Write-Host -Object "Checking Existing Settings for $($NetworkAdapter.Name)... DONE" -ForegroundColor Green
        If (Check-DNSSettings4 -NetworkAdapter $NetworkAdapter)
        {
        #if DNS settings are set correctly
        
        
        }
        else
        {
        #if DNS setting are not set correctly
        If (Set-DNSSettings4 -NetworkAdapter $NetworkAdapter)
            {Write-Host -Object "Changing DNS Servers: 8.8.8.8 and 8.8.4.4 for $($NetworkAdapter.Name)... DONE" -ForegroundColor Green}
        else
            {Write-Host -Object "Changing DNS Servers: 8.8.8.8 and 8.8.4.4 for $($NetworkAdapter.Name)... FAULT" -ForegroundColor Red}
        }
    }
    
    #Flushing Cache...: ipconfig /flushcash ... DONE
    Write-Host "Flushing Cache...: ipconfig /flushcash..." -ForegroundColor Green -NoNewline
    Flush-Cache4
    Write-Host "DONE" -ForegroundColor Green 

    #Checking Hosts File: Check for bad entries that could be limiting the user access.. DONE
    Write-Host "Checking Hosts File: Check for bad entries that could be limiting the user access..." -ForegroundColor Green -NoNewline
    Check-HostsFile
    Write-Host "DONE" -ForegroundColor Green 

    #- Check if it can ping and reach by web www.google.com
    $test_connection_site = "www.google.com"
    If ((Test-Connection $test_connection_site -Quiet) -and ((Invoke-WebRequest -Uri $test_connection_site -UseBasicParsing).StatusCode -eq 200))
    {
        Write-Host -Object "After checking your DNS settings, DNS Geek has detected internet connectivty and was also able to connect and establish connection to Google.com which indicates that the internet and the DNS are functioning properly." -ForegroundColor Green
    }
    else
    {
        Write-Host -Object "After checking your DNS settings, DNS Geek has NOT detected internet connectivty and was NOT also able to connect and establish connection to Google.com which indicates that the internet and the DNS are functioning properly." -ForegroundColor Red
    }
    #-Type Y if you think the issue is fixed
    Do
    {
    $Key = Read-Host -Prompt "Type Y if you think the issue is fixed or type N if you think the issue is not fixed." 
    } Until (($Key -eq "y") -or ($Key -eq "n"))
    If ($Key -eq "y")
    {
        #Since the issue has been fixed, DNS Geek will now close. Exit (Powershell)
        Write-Host -Object "Since the issue has been fixed, DNS Geek will now close. Exit (Powershell)" -ForegroundColor Green
        return
    }
    else
    {
        $name_of_site = Read-Host -Prompt "Please type the site address in this format (www.google.com): name of site"
        If (Check-Site4 -Site $name_of_site)
        {
            
        }
        else
        {
            Do
            {$Key = Read-Host -Prompt "Please do the following, turn off your router and modem if there is 1, and wait 5 minutes. Then turn your router/modem back on, and wait 5 more minutes. Once this is done, press Y"} 
            Until ($Key -eq "y")
            Check-Site4 -Site $name_of_site | Out-Null
            
        }
        

        Do
        {$Key = Read-Host -Prompt "If the site is now opening, type: Y, if the site is not opening type: N"} 
        Until (($Key -eq "y") -or ($Key -eq "n"))
        If ($Key -eq "y")
        {
            Write-Host -Object  "Since the issue has been fixed, DNS Geek will now close." -ForegroundColor Green
            return
        }
        else
        {
            Write-Host -Object  "The site is Down. Try after 24 hours, and if it still doesn't work, e-mail: kevinarrows@appuals.com so an expert can diagnose this for you." -ForegroundColor Red
            return   
        }
        
    }
    
    

        
}
else
{
    #PowerShell version is 2 or 3
    $Interfaces = get-wmiobject -class win32_networkadapterconfiguration | where-object { (get-wmiobject -class win32_networkadapter -filter "physicaladapter=$true" | where-object {($_.PNPDeviceID -notmatch "^ROOT") -and ($_.Name -notmatch "Bluetooth") -and ($_.Name -notmatch "blackberry") -and ($_.Name -notmatch "^Microsoft")} | select -expand name) -contains $_.description }
    Foreach ($Interface in $Interfaces)
    {
        Write-Host -Object "Checking Existing Settings for $($Interface.Description)... DONE" -ForegroundColor Green
        If (Check-DNSSettings2 -NetworkAdapter $Interface)
        {
        #if DNS settings are set correctly
        
        
        }
        else
        {
        #if DNS setting are not set correctly
        If (Set-DNSSettings2 -NetworkAdapter $Interface)
            {Write-Host -Object "Changing DNS Servers: 8.8.8.8 and 8.8.4.4 for $($Interface.Description)... DONE" -ForegroundColor Green}
        else
            {Write-Host -Object "Changing DNS Servers: 8.8.8.8 and 8.8.4.4 for $($Interface.Description)... FAULT" -ForegroundColor Red}
            
        }
    }

    #Flushing Cache...: ipconfig /flushcash ... DONE
    Write-Host "Flushing Cache...: ipconfig /flushcash..." -ForegroundColor Green -NoNewline
    Flush-Cache2
    Write-Host "DONE" -ForegroundColor Green 

    #Checking Hosts File: Check for bad entries that could be limiting the user access.. DONE
    Write-Host "Checking Hosts File: Check for bad entries that could be limiting the user access..." -ForegroundColor Green -NoNewline
    Check-HostsFile
    Write-Host "DONE" -ForegroundColor Green 

    #- Check if it can ping and reach by web www.google.com
    $test_connection_site = "www.google.com"
    
    If ((Test-Connection $test_connection_site -Quiet))
    {
        Write-Host -Object "After checking your DNS settings, DNS Geek has detected internet connectivty and was also able to connect and establish connection to Google.com which indicates that the internet and the DNS are functioning properly." -ForegroundColor Green
    }
    else
    {
        Write-Host -Object "After checking your DNS settings, DNS Geek has NOT detected internet connectivty and was NOT also able to connect and establish connection to Google.com which indicates that the internet and the DNS are functioning properly." -ForegroundColor Red
    }
    #-Type Y if you think the issue is fixed
    Do
    {
    $Key = Read-Host -Prompt "Type Y if you think the issue is fixed or type N if you think the issue is not fixed." 
    } Until (($Key -eq "y") -or ($Key -eq "n"))
    If ($Key -eq "y")
    {
        #Since the issue has been fixed, DNS Geek will now close. Exit (Powershell)
        Write-Host -Object "Since the issue has been fixed, DNS Geek will now close. Exit (Powershell)" -ForegroundColor Green
        return
    }
    else
    {
        $name_of_site = Read-Host -Prompt "Please type the site address in this format (www.google.com): name of site"
        If (Check-Site2 -Site $name_of_site)
        {
            
        }
        else
        {
            Do
            {$Key = Read-Host -Prompt "Please do the following, turn off your router and modem if there is 1, and wait 5 minutes. Then turn your router/modem back on, and wait 5 more minutes. Once this is done, press Y"} 
            Until ($Key -eq "y")
            Check-Site2 -Site $name_of_site | Out-Null
            
        }
        

        Do
        {$Key = Read-Host -Prompt "If the site is now opening, type: Y, if the site is not opening type: N"} 
        Until (($Key -eq "y") -or ($Key -eq "n"))
        If ($Key -eq "y")
        {
            Write-Host -Object  "Since the issue has been fixed, DNS Geek will now close." -ForegroundColor Green
            return
        }
        else
        {
            Write-Host -Object  "The site is Down. Try after 24 hours, and if it still doesn't work, e-mail: kevinarrows@appuals.com so an expert can diagnose this for you." -ForegroundColor Red
            return   
        }
        
    }


}

 
   
}
End
{
}

