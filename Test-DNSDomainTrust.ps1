## Domain Trust DNS Testing
$IPList = '192.168.1.4','192.168.1.10','10.201.2.10','172.20.0.5','172.20.0.6'
$FQDN = 'USONVSVRDC01.USON.LOCAL','USONVSVRDC02.USON.LOCAL','USONVSVRDC03.USON.LOCAL','CLFRDC01.cloud.local','CLFRDC02.cloud.local'
$CN = 'USONVSVRDC01','USONVSVRDC02','USONVSVRDC03','CLFRDC01','CLFRDC02'

ForEach($IP in $IPList){
    if (test-connection $IP -quiet) { write-output "$IP Alive" }
        else
      { write-output "$IP Not Responding" }}
ForEach($fq in $FQDN){
    if (test-connection $fq -quiet) { write-output "$fq Alive" }
        else
      { write-output "$fq Not Responding" }}
ForEach($name in $CN){
    if (test-connection $name -quiet) { write-output "$name Alive" }
        else
      { write-output "$name Not Responding" }}