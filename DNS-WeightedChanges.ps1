###### Set Parameters LASDC01 ######
Invoke-Command -ComputerName LASDC01 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvPriority" -Value "10" }
Invoke-Command -ComputerName LASDC01 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvWeight" -Value "100" }

###### Set Parameters LASDC02 ######
Invoke-Command -ComputerName LASDC02 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvPriority" -Value "10" }
Invoke-Command -ComputerName LASDC02 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvWeight" -Value "50" }

###### Set Parameters LASDC03 ######
Invoke-Command -ComputerName LASDC03 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvPriority" -Value "100" }
Invoke-Command -ComputerName LASDC03 {Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" -Name "LdapSrvWeight" -Value "10" }

###### Check the New Parameters ######
Invoke-Command -ComputerName LASDC01 {Get-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" }
Invoke-Command -ComputerName LASDC02 {Get-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" }
Invoke-Command -ComputerName LASDC03 {Get-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\services\Netlogon\Parameters" }

###### Restart NetLogon Service ######
#Get-Service -ComputerName LASDC01 -Name Netlogon | Restart-Service -verbose
#Get-Service -ComputerName LASDC02 -Name Netlogon | Restart-Service -verbose
#Get-Service -ComputerName LASDC03 -Name Netlogon | Restart-Service -verbose 
