#remove zones commented out
Remove-DemoZones $DCs

#Remove contosouniversity.edu conditional forwarder
#may have a bug here around some missing powershell cmdlets


#function to remove zone
Function Remove-DemoZones ($DCs)
{
    foreach ($DC in $DCs) 
    {
        Remove-dnsserverzone -Name ContosoUniversity.edu -ComputerName $DC.Name -PassThru -Force
        
    } 
    Return
}

