<#
.NOTES
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages.

.SYNOPSIS
Extract a sub-DNS zone from a .dns file and export the result into a new .dns file

.DESCRIPTION
The goal of this script is to help implementing KB255248:
"How To Create a Child Domain in Active Directory and Delegate the DNS Namespace to the Child Domain"

.LINK
http://support.microsoft.com/kb/255248

.INPUTS
A DNS file containing an export of the DNS Zone.

.OUTPUTS
A DNS file containing the child DNS namespace records.

.VERSIONS
1.1 Fixe an issue with wildcards DNS records. 

.EXAMPLE
 .\Extract-DNSZone.PS1 -inputFile ".\contoso.corp.dns" -outputFile ".\child.contoso.corp.dns" -extractZoneName "child"
#>

param(
    [string]$inputFile="",
    [string]$outputFile="",
    [string]$extractZoneName=""
)

if([string]::IsNullOrEmpty($inputFile))
{
    $inputFile = Read-Host "Please type the name of the DNS input file (ex: contoso.corp.dns)"
}
Write-Output "Opening file: ""$inputFile""..."
$fileContent = Get-Content $inputFile -ErrorAction Stop

if([string]::IsNullOrEmpty($outputFile))
{
    $outputFile = Read-Host "Please type the name of the DNS output file (ex: child.contoso.corp.dns). The file will be created or overwritten"
}
if(Test-Path $outputFile) #If the file already exists
{
       $yes = new-object system.Management.automation.host.ChoiceDescription("&Yes",0)
       $no = new-object system.Management.automation.host.ChoiceDescription("&No",1)
       if($host.ui.promptForChoice("File already exists","Would you like to overwrite the file?",[system.management.automation.host.choiceDescription[]]@($yes,$no),0) -ne 0)
       {
            return "Canceled."
       }
}
Set-Content $outputFile "" -Force -ErrorAction Stop #Create an empty file.

if([string]::IsNullOrEmpty($extractZoneName))
{
    $extractZoneName = Read-Host "Please enter the name of the domain to extract (ex: child)"
}
$outputContent = @() #this variable will be used to build the future output file
$recordName = $null
$SectionZoneRecordsReached = $false
$nbRecordsExtracted = 0

Write-Output "Extracting records for domain: ""$extractZoneName""..."
for ($i = 0; $i -lt $fileContent.Count; $i++)
{
    #Just write a progress bar. This line can be removed if needed.
    if(!($i%100)) {Write-Progress -PercentComplete (($i/$fileContent.Count)*100) -Activity "Extracting DNS records..." -Status "Parsing line $i on $($fileContent.Count)"}
    
    if($fileContent[$i] -like ';*') #If line starts with ';'
    {
        if($fileContent[$i] -match "^;\s+Database file .+ for (?<SourceZoneName>.+) zone.$")
        {
            $outputContent += ";  Database file $outputFile for $extractZoneName.$($Matches.SourceZoneName) zone."
        }
        else
        {
            $outputContent += $fileContent[$i]
        }

        if($fileContent[$i] -match "^;\s+Zone records") #If we have reached the file section containing DNS records
        {
            $SectionZoneRecordsReached = $true
        }
    }
    elseif($fileContent[$i] -like '@*' -and !$SectionZoneRecordsReached) #If line starts with '@' before
    {
        $outputContent += $fileContent[$i]
    }
    elseif($SectionZoneRecordsReached) #If we have reached the "Zone records" section of the file
    {
        if($fileContent[$i][0] -eq ' ')#if line starts with blank space
        {
            if([string]::IsNullOrEmpty($recordName)) #if $recordName have never been assigned
            {
                Write-Error "Unable to find the parent for record $($fileContent[$i])"
            }
            else
            {
                $recordName = $recordName #recordName is the same than previous the line
            }
        }
        else
        {
            $lineArray = $fileContent[$i].Split("`t") #split on tabulation
            $lineArray = $lineArray[0].Split(" ") #split on blank space
            $recordName = $lineArray[0] #recordName is the first element of the line (before tabulation and space)
        }

        if($recordName -match "\.$extractZoneName$")
        {
                $newRecordName = $recordName -replace ".$extractZoneName$", ""

                #$DNSRecord = $fileContent[$i] -replace "^$recordName", "$newRecordName"                
                if($recordName.StartsWith('*'))
                {
                $DNSRecord = $fileContent[$i] -replace "^\$recordName", "$newRecordName"
                }
                else
                {
                $DNSRecord = $fileContent[$i] -replace "^$recordName", "$newRecordName"                
                }
                $outputContent += $DNSRecord
                $nbRecordsExtracted ++
        }
    }
    else
    {
        $outputContent += $fileContent[$i]
    }
}

$outputContent | Set-Content -Encoding UTF8 $outputFile
Write-Host "Done. $nbRecordsExtracted Records have been extracted in ""$outputFile""."
Write-Host "Please manually review the NS and SOA records."
