#https://stackoverflow.com/questions/35083798/flushdns-and-registerdns-on-multiple-machine-by-powershell/35088512#35088512

$listofservers = Get-Content .\servers.txt

foreach ($servers in $listofservers) {

Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /flushdns") -ComputerName $servers

Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /registerdns") -ComputerName $servers

}
ReturnValue


$listofservers = Get-Content .\servers.txt

foreach ($servers in $listofservers) {

Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /flushdns > c:\flushdnsresult.txt") -ComputerName $servers

Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /registerdns > c:\registerdnsresult.txt") -ComputerName $servers

}