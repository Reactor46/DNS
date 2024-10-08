# 
# Set DNS Forwarders Essentials 2011 & 2012 (v0.2)
# Robert Pearman SBS MVP
# 

# Enter IP Addresses to Set as Forwarders seperate multiple values with a comma.
# eg. "8.8.8.8", "9.9.9.9"
$forwarders = "XXX.XXX.XXX.XXX", "XXX.XXX.XXX.XXX"

# Run Unattended
Set-ItemProperty -path hklm:\system\CurrentControlSet\services\dns\parameters -name forwarders $forwarders
Restart-Service DNS
