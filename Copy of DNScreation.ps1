Import-CSV c:\script\test.csv | foreach {dnscmd /RecordAdd $_.Zone $_.hostname /createPTR A $_.IPaddress}

