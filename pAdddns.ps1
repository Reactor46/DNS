#'****************************************************** 
# Author: Thiago Cardoso  
# Version: 1.0 
# last modified: 09/14/2011 
# This script create register A on Dns Server with csv list.
# Example: 
# CSV type: adddns.csv 
# name,IP
# server01,192.168.0.1
#***************************************************** 

$dns="DnsServer"
$zone="Zone"
Import-Csv adddns.csv | foreach {
	dnscmd $dns /recordadd $zone $($_.name) A $($_.ip)
}