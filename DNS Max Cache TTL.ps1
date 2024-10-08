# DNS Max Cache TTL Value
# Robert Pearman
# versrion 0.1
#
# A script to set the max cache DNS TTL Value as Referenced here: http://support.microsoft.com/default.aspx?scid=kb;EN-US;968372
#
#
# Check For Elevation
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator" ))
{
    Write-Host "You must run PowerShell 'As Administrator' to use this tool." -foregroundcolor YELLOW
    Write-Host ""
    
}
else
{

    # Check For DNS Server Service
    if ((Test-Path -path HKLM:SYSTEM\CurrentControlSet\Services\DNS\Parameters) -ne "True")
    {
        Write-Host "We have not Detected the DNS Server Service" -Foregroundcolor Red
    }

    else
    {
        # Test Backup Path
        $p = "c:\Registry-Backup"
        if (!(Test-Path -path $p))
        {
            New-Item $p -type directory
        }
        # Export Registry Key
        Regedit /e "$p\DNS.reg" HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DNS\Parameters
        Write-Host "Registry Key Exported to $p" -Foregroundcolor Green
        Write-Host "Adding MAX Cache TTL Value"
        New-ItemProperty -path HKLM:\System\CurrentControlSet\Services\DNS\Parameters -Name "MaxCacheTTL" -PropertyType DWORD -Value 0x2A300
        if ((get-itemproperty HKLM:\System\CurrentControlSet\Services\DNS\Parameters | foreach { $_.MaxCacheTTL } ) -ne "172800")
        {
            Write-Host "Value Not Set Correctly" -Foregroundcolor Red
        }
        
        else
        {
            Write-Host "Max Cache TTL Value Set to 172800 (2 days)" -foregroundcolor Green
        }
        
    }
}
# End
