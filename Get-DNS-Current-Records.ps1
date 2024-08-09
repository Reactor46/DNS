$TestCSVFile = “C:\LazyWinAdmin\DNS\SRVPWReport.CSV”
$GDCList = “C:\LazyWinAdmin\DNS\DCList.TXT”
Remove-item $TestCSVFile -ErrorAction SilentlyContinue
$ThisString=”Domain Name, Domain Controller, AD Site, SRV, Weight, Priority,Final Status”
Add-Content “$TestCSVFile” $ThisString
$PDCServerToConnect=”LASDC01”
$ThisDomain = “Contoso.corp”
$TestStatus=”Passed”
$TestText = “”
$sumVal=0
$ReachOrNot = “Yes”
$AnyGap = “No”
$TotNo = 0
$AnyOneOk = “No”
$SRVFile = “C:\LazyWinAdmin\DNS\SRVTempRC.DPC”
Remove-item $SRVFile -ErrorAction SilentlyContinue
$ThisZoneNow = “_msdcs” #+$ThisDomain
$Error.Clear()
Get-DnsServerResourceRecord -ComputerName $PDCServerToConnect -ZoneName $ThisDomain -Name $ThisZoneNow | ? {($_.recordtype -eq ‘SRV’)} | Select -Property HostName,RecordType -ExpandProperty RecordData | export-csv $SRVFile -NoTypeInformation
IF ($Error.Count -eq 0)
{
$AnyOneOk=”Yes”
$AllRecordsCSV = Import-CSV $SRVFile
$AllDCInDomain=Get-ADDomainController -filter * -Server $ThisDomain
ForEach ($DCName in $AllDCInDomain)
{
$ThisDCNameNow = $DCName.HostName
$ThisDCSiteNow = $DCName.Site
ForEach ($SRVInFile in $AllRecordsCSV)
{
$ThisDCInFile = $SRVInFile.DomainName
$ThisDCSRV = $SRVInFile.Hostname
$ThisWeight = $SRVInFile.Weight
$ThisPriority = $SRVInFile.Priority
$SRVToCheckNow = $ThisDCSRV+”.”+$ThisDCInFile
$FinStatus=””
IF ($ThisWeight -eq 100 -and $ThisPriority -eq 0)
{

}else{

$AnyGap = “Yes”
$FinStatus = “Please check why Weight and Priority of this domain controller has been set to values other than 100 and 0 respectively.”
$FinalSTR = $ThisDomain+”,”+$ThisDCNameNow+”,”+$ThisDCSiteNow+”,”+$SRVToCheckNow+”,”+$ThisWeight+”,”+$ThisPriority+”,”+$FinStatus
Add-Content “$TestCSVFile” $FinalSTR
}
}

}else{6

$ThisSTR = $ThisDomain+”,Error Connecting to PDC in this domain.”
$ErrorOrNot = “Yes”
Add-Content “$TestCSVFile” $ThisStr
}6
}

IF ($AnyGap -eq “Yes”)
{7
$TestStatus=”Critical”
$TestText = “Weight and Priority for domain controller SRV records have been modified from default 100 and 0 values. Please ensure Weight and Priority have been modified to meet a purpose.”
$SumVal = $TotNo
}7
IF ($AnyGap -eq “No”)
{8
$TestStatus=”Passed”
$TestText = “All Domain Controllers are using default weight and priority.”
$SumVal = “”
}8
$STR = $ADTestName +”,”+$TestStartTime+”,”+$TestStatus+”,”+$SumVal +”,”+$TestText