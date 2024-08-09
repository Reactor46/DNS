$AllServers=Get-ADComputer -Filter {Operatingsystem -Like 'Windows Server*' -and Enabled -eq 'true'}
ForEach ($Server in $AllServers){
  $Result=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" -Property DNSServerSearchOrder -ComputerName $Server.Name -ErrorAction SilentlyContinue
  $output = new-object PSObject 
  $output | add-member NoteProperty "ComputerName" $Server.Name
  $output | add-member NoteProperty "DNSServerSearchOrder" $Result.DNSServerSearchOrder
  $output | Out-FileUtf8NoBom -Append E:\DNS-Settings.txt
}