# Get-DNSandWINS.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

# Version history:
#
# 2.0 (2013-10-02)
# * Added -Credential
# * Output data only for IPv4 addresses
# * Output separate row for each DNS server address
#
# 1.0 (2012-02-15)
# * Initial version

<#
.SYNOPSIS
Outputs the computer name, IP address(es), DNS server address(es), and WINS server addresses for one or more computers.

.DESCRIPTION
Outputs the computer name, IP address(es), DNS server address(es), and WINS server addresses for one or more computers.

.PARAMETER ComputerName
One or more computer names. This parameter accepts pipeline input.

.PARAMETER Credential
Specifies credentials for the WMI connection.

.EXAMPLE
PS C:\> Get-DNSandWINS server1
Outputs information for server1.

.EXAMPLE
PS C:\> Get-DNSandWINS server1,server2
Outputs information for server1 and server2.

.EXAMPLE
PS C:\> Get-DNSandWINS (Get-Content ComputerList.txt)
Outputs information for the computers listed in ComputerList.txt.

.EXAMPLE
PS C:\> Get-Content ComputerList.txt | Get-DNSandWINS
Same as previous example (Outputs information for the computers listed in ComputerList.txt).

.EXAMPLE
PS C:\> Get-DNSandWINS server1,server2 -Credential (Get-Credential)
Outputs information for server1 and server2 using different credentials.
#>

param(
  [parameter(ValueFromPipeline=$TRUE)]
    [String[]] $ComputerName=$Env:COMPUTERNAME,
    [System.Management.Automation.PSCredential] $Credential
)

begin {
  $PipelineInput = (-not $PSBOUNDPARAMETERS.ContainsKey("ComputerName")) -and (-not $ComputerName)

  # Outputs the computer name, IP address, and DNS and WINS settings for
  # every IP-enabled adapter on the specified computer that's configured with
  # an IPv4 address.
  function Get-IPInfo($computerName) {
    $params = @{
      "Class" = "Win32_NetworkAdapterConfiguration"
      "ComputerName" = $computerName
      "Filter" = "IPEnabled=True"
    }
    if ( $Credential ) { $params.Add("Credential", $Credential) }
    get-wmiobject @params | foreach-object {
      foreach ( $adapterAddress in $_.IPAddress ) {
        if ( $adapterAddress -match '(\d{1,3}\.){3}\d{1,3}' ) {
          foreach ( $dnsServerAddress in $_.DNSServerSearchOrder ) {
            new-object PSObject -property @{
              "ComputerName" = $_.__SERVER
              "IPAddress" = $adapterAddress
              "DNSServer" = $dnsServerAddress
              "WINSPrimaryServer" = $_.WINSPrimaryServer
              "WINSSecondaryServer" = $_.WINSSecondaryServer
            } | select-object ComputerName,IPAddress,DNSServer,WINSPrimaryServer,WINSSecondaryServer
          }
        }
      }
    }
  }
}

process {
  if ( $PipelineInput ) {
    Get-IPInfo $_
  }
  else {
    $ComputerName | foreach-object {
      Get-IPInfo $_
    }
  }
}
