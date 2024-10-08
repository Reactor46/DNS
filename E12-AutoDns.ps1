# Essentials 2012 & R2 Auto DNS Config Tool
# Robert Pearman
# v0.1
$ErrorActionPreference = "SilentlyContinue"

# Check for Elevation
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator" ))
{
    Write-Host "You must run PowerShell 'As Administrator' to use this tool." -foregroundcolor YELLOW
    Write-Host ""
    
}
else
{
    # Registry Path
    $Cregistry = "HKLM:\SOFTWARE\Microsoft\Windows Server\Networking\ServerDiscovery"
    $ClientKey = "SkipAutoDnsServerDetection"
    $Sregistry = "HKLM:\SOFTWARE\Microsoft\Windows Server\Networking\ClientDNS"
    $ServerKey = "SkipAutoDnsConfig"
    

    # Check OS Version
    $Computer =  $env:ComputerName
    $os = (GWMI Win32_OPeratingSystem).Caption
    $check = $os.Contains("Essentials")
    if (($check) -ne "True")
    {
        # Client OS
        Write-Host "Computer Name: "-nonewline -foregroundcolor yellow; Write-Host "$Computer" -foregroundcolor Cyan
        Write-Host "Client OS: " -nonewline -foregroundcolor yellow; Write-Host "$os" -foregroundcolor Cyan
        
        # Check for existing Registry Value
        $regCheck = (Get-ItemProperty $Cregistry -Name $ClientKey | Foreach { $_.$ClientKey } )
        if (($regCheck) -eq $null)
        {
            # Value Not Set
            Write-Host "Registry Value not Set"
            Write-Host "Disable DNS AutoDiscover? Y/N"
            $set = Read-Host
            if (($set) -ne "Y")
            {
                New-ItemProperty $Cregistry -Name $ClientKey -PropertyType String -Value False | out-null
                $essentialsR1 = (Get-Service -DisplayName "Windows Server LAN Configuration" | foreach { $_.DisplayName} )
                if (($essentialsR1) -eq "Windows Server LAN Configuration")
                {
                    Restart-Service "Windows Server LAN Configuration"
                }
                Write-Host "Skip DNS AutoDiscover has been Disabled"    
            }
            else
            {
                New-ItemProperty $Cregistry -Name $ClientKey -PropertyType String -Value True  | out-null
                $essentialsR1 = (Get-Service -DisplayName "Windows Server LAN Configuration" | foreach { $_.DisplayName} )
                if (($essentialsR1) -eq "Windows Server LAN Configuration")
                {
                    Restart-Service "Windows Server LAN Configuration"
                }
                Write-Host "Skip DNS AutoDiscover has been Enabled"   
            }
        }
        if (($regCheck) -eq "True")
        {
            # Value Set True
            Write-Host "Skip DNS AutoDiscover is: " -nonewline -foregroundcolor Yellow; Write-Host "Enabled" -foregroundcolor Green 
            Write-Host "Change? Y/N"
            $change = Read-Host
            if (($change) -ne "Y")
            {
            
            }
            else
            {
                # Set Value False
                Set-ItemProperty $Cregistry -Name $ClientKey -Value False | out-null 
                $essentialsR1 = (Get-Service -DisplayName "Windows Server LAN Configuration" | foreach { $_.DisplayName} )
                if (($essentialsR1) -eq "Windows Server LAN Configuration")
                {
                    Restart-Service "Windows Server LAN Configuration"
                }
                Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Disabled" -foregroundcolor Red
            }
        } 
        if (($regCheck) -eq "False")
        {
            # Value Set False
            Write-Host "Skip DNS AutoDiscover is: " -nonewline -foregroundcolor Yellow; Write-Host "Disabled" -foregroundcolor Red
            Write-Host "Change? Y/N"
            $change = Read-Host
            if (($change) -ne "Y")
            {
            
            }
            else
            {
                # Set Value True
                Set-ItemProperty $Cregistry -Name $ClientKey -Value True | out-null 
                Restart-Service "Windows Server LAN Configuration"
             
            }
            Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Enabled" -foregroundcolor Green
        } 
        
        
            
    }
    else
    {
        # Server OS
        Write-Host "Server Name: "-nonewline -foregroundcolor yellow; Write-Host "$Computer" -foregroundcolor Cyan
        Write-Host "Server OS: " -nonewline -foregroundcolor yellow; Write-Host "$os" -foregroundcolor Cyan
        
        # Check for existing Registry Value
        $Path = (Test-Path $SRegistry)
        if (($path) -ne "true")
        {
            # New Key
            New-Item -path "HKLM:\Software\Microsoft\Windows Server\Networking" -Name "ClientDNS" | out-null
            Write-Host "Client 'Skip AutoDNS Discover'  has not been configured." -foregroundcolor CYAN 
            Write-Host "Do you want to Enable it? Y/N" -foregroundcolor yellow
            $check = Read-Host
            if (($check) -ne "Y")
            {
                New-ItemProperty $Sregistry -Name $ServerKey -PropertyType DWORD -Value 0 | out-null
                Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Disabled" -foregroundcolor Red
            }
            else
            {
                New-ItemProperty $Sregistry -Name $ServerKey -PropertyType DWORD -Value 1  | out-null
                Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Enabled" -foregroundcolor Green   
            }
            
        }
        else
        {
        $regCheck = (Get-ItemProperty $Sregistry -Name $ServerKey | Foreach { $_.$ServerKey } )
        if (($regCheck) -eq $null)
        {
            # Value Not Set
            Write-Host "Registry Value not Set"
            Write-Host "Disable DNS AutoDiscover? Y/N"
            $set = Read-Host
            if (($set) -ne "Y")
            {
                New-ItemProperty $Sregistry -Name $ServerKey -PropertyType DWORD -Value 0 | out-null
                Write-Host "Skip DNS AutoDiscover has been Disabled"    
            }
            else
            {
                New-ItemProperty $Sregistry -Name $ServerKey -PropertyType DWORD -Value 1  | out-null
                Write-Host "Skip DNS AutoDiscover has been Enabled"   
            }
        }
        if (($regCheck) -eq "1")
        {
            # Value Set 1
            Write-Host "Skip DNS AutoDiscover is: " -nonewline -foregroundcolor Yellow; Write-Host "Enabled" -foregroundcolor Green 
            Write-Host "Change? Y/N"
            $change = Read-Host
            if (($change) -ne "Y")
            {
            
            }
            else
            {
                # Set Value 0
                Set-ItemProperty $Sregistry -Name $ServerKey -Value 0 | out-null 
                Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Disabled" -foregroundcolor Red
            }
        } 
        if (($regCheck) -eq "0")
        {
            # Value Set 0
            Write-Host "Skip DNS AutoDiscover is: " -nonewline -foregroundcolor Yellow; Write-Host "Disabled" -foregroundcolor Red
            Write-Host "Change? Y/N"
            $change = Read-Host
            if (($change) -ne "Y")
            {
            
            }
            else
            {
                # Set Value 1
                Set-ItemProperty $Sregistry -Name $ServerKey -Value 1 | out-null 
                Write-Host "Skip DNS AutoDiscover has been: " -nonewline -foregroundcolor Yellow; Write-Host "Enabled" -foregroundcolor Green
                
            }
        } 
    }   
 }
        
}




