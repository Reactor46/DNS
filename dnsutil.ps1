param([String] $dnsqtype  = $(throw "Please specify the DNS Query Type"),[String] $IpParam  = $(throw "Please specify the IPaddress"))

function Compile-Csharp ([string] $code, [Array]$References) {

# Get an instance of the CSharp code provider
$cp = New-Object Microsoft.CSharp.CSharpCodeProvider

$refs = New-Object Collections.ArrayList
$refs.AddRange( @("${framework}System.dll",
# "${PsHome}\System.Management.Automation.dll",
# "${PsHome}\Microsoft.PowerShell.ConsoleHost.dll",
"${framework}System.Windows.Forms.dll",
"${framework}System.Data.dll",
"${framework}System.Drawing.dll",
"${framework}System.XML.dll"))
if ($References.Count -ge 1) {
$refs.AddRange($References)
}

# Build up a compiler params object...
$cpar = New-Object System.CodeDom.Compiler.CompilerParameters
$cpar.GenerateInMemory = $true
$cpar.GenerateExecutable = $false
$cpar.IncludeDebugInformation = $false
$cpar.CompilerOptions = "/target:library"
$cpar.ReferencedAssemblies.AddRange($refs)
$cr = $cp.CompileAssemblyFromSource($cpar, $code)

if ( $cr.Errors.Count) {
$codeLines = $code.Split("`n");
foreach ($ce in $cr.Errors) {
write-host "Error: $($codeLines[$($ce.Line - 1)])"
$ce | out-default
}
Throw "INVALID DATA: Errors encountered while compiling code"
}
}

$code = @'
namespace PAB.DnsUtils
{
    using System;
    using System.Collections;
    using System.ComponentModel;
    using System.Runtime.InteropServices;
    public class Dns 
        { 
        public Dns() 
        { 
        } 

        [DllImport("Dnsapi", EntryPoint="DnsQuery_W", CharSet=CharSet.Unicode, SetLastError=true, ExactSpelling=true)] 
        private static extern Int32 DnsQuery([MarshalAs(UnmanagedType.VBByRefStr)]ref string sName, QueryTypes wType, QueryOptions options, UInt32 aipServers, ref IntPtr ppQueryResults, UInt32 pReserved); 
        [DllImport("Dnsapi", CharSet=CharSet.Auto, SetLastError=true)] 
        private static extern void DnsRecordListFree(IntPtr pRecordList, int FreeType); 

        public enum ErrorReturnCode 
           { 
            DNS_ERROR_RCODE_NO_ERROR = 0, 
            DNS_ERROR_RCODE_FORMAT_ERROR = 9001, 
            DNS_ERROR_RCODE_SERVER_FAILURE = 9002, 
            DNS_ERROR_RCODE_NAME_ERROR = 9003, 
            DNS_ERROR_RCODE_NOT_IMPLEMENTED = 9004, 
            DNS_ERROR_RCODE_REFUSED = 9005, 
            DNS_ERROR_RCODE_YXDOMAIN = 9006, 
            DNS_ERROR_RCODE_YXRRSET = 9007, 
            DNS_ERROR_RCODE_NXRRSET = 9008, 
            DNS_ERROR_RCODE_NOTAUTH = 9009, 
            DNS_ERROR_RCODE_NOTZONE = 9010, 
            DNS_ERROR_RCODE_BADSIG = 9016, 
            DNS_ERROR_RCODE_BADKEY = 9017, 
            DNS_ERROR_RCODE_BADTIME = 9018 
            } 

            private enum QueryOptions 
            { 
            DNS_QUERY_ACCEPT_TRUNCATED_RESPONSE = 1, 
            DNS_QUERY_BYPASS_CACHE = 8, 
            DNS_QUERY_DONT_RESET_TTL_VALUES = 0x100000, 
            DNS_QUERY_NO_HOSTS_FILE = 0x40, 
            DNS_QUERY_NO_LOCAL_NAME = 0x20, 
            DNS_QUERY_NO_NETBT = 0x80, 
            DNS_QUERY_NO_RECURSION = 4, 
            DNS_QUERY_NO_WIRE_QUERY = 0x10, 
            DNS_QUERY_RESERVED = -16777216, 
            DNS_QUERY_RETURN_MESSAGE = 0x200, 
            DNS_QUERY_STANDARD = 0, 
            DNS_QUERY_TREAT_AS_FQDN = 0x1000, 
            DNS_QUERY_USE_TCP_ONLY = 2, 
            DNS_QUERY_WIRE_ONLY = 0x100 
            } 

            public enum QueryTypes 
            { 
            DNS_TYPE_A = 1, 
            DNS_TYPE_CNAME = 5, 
            DNS_TYPE_MX = 15, 
            DNS_TYPE_TEXT = 16, 
            DNS_TYPE_SRV = 33, 
            DNS_TYPE_PTR = 12

            } 

            [StructLayout(LayoutKind.Explicit)] 
            private struct DnsRecord 
            { 
            [FieldOffset(0)] 
            public IntPtr pNext; 
            [FieldOffset(4)] 
            public string pName; 
            [FieldOffset(8)] 
            public short wType; 
            [FieldOffset(10)] 
            public short wDataLength; 
            [FieldOffset(12)] 
            public uint flags; 
            [FieldOffset(16)] 
            public uint dwTtl; 
            [FieldOffset(20)] 
            public uint dwReserved; 

            // below is a partial list of the unionized members for this struct 

            // for DNS_TYPE_A records 
            [FieldOffset(24)] 
            public uint a_IpAddress; 

            // for DNS_TYPE_ PTR, CNAME, NS, MB, MD, MF, MG, MR records 
            [FieldOffset(24)] 
            public IntPtr ptr_pNameHost; 

            // for DNS_TXT_ DATA, HINFO, ISDN, TXT, X25 records 
            [FieldOffset(24)] 
            public uint data_dwStringCount; 
            [FieldOffset(28)] 
            public IntPtr data_pStringArray; 

            // for DNS_TYPE_MX records 
            [FieldOffset(24)] 
            public IntPtr mx_pNameExchange; 
            [FieldOffset(28)] 
            public short mx_wPreference; 
            [FieldOffset(30)] 
            public short mx_Pad; 

            // for DNS_TYPE_SRV records 
            [FieldOffset(24)] 
            public IntPtr srv_pNameTarget; 
            [FieldOffset(28)] 
            public short srv_wPriority; 
            [FieldOffset(30)] 
            public short srv_wWeight; 
            [FieldOffset(32)] 
            public short srv_wPort; 
            [FieldOffset(34)] 
            public short srv_Pad; 

            } 

            public static string[] GetRecords(string domain, string dnsqtype) 
            { 
            IntPtr ptr1 = IntPtr.Zero ; 
            IntPtr ptr2 = IntPtr.Zero ;
            DnsRecord rec;
            Dns.QueryTypes qtype = QueryTypes.DNS_TYPE_PTR;
            switch(dnsqtype){
                case "MX":
                    qtype = QueryTypes.DNS_TYPE_MX;
                    break;
                case "PTR":
                    qtype = QueryTypes.DNS_TYPE_PTR;
                    break;
                case "SPF":
                    qtype = QueryTypes.DNS_TYPE_TEXT;
                    break;
                case "A":
                    qtype = QueryTypes.DNS_TYPE_A;
                    break;
            }
           
            if(Environment.OSVersion.Platform != PlatformID.Win32NT) 
            { 
            throw new NotSupportedException(); 
            } 

            ArrayList list1 = new ArrayList(); 
            int num1 = DnsQuery(ref domain, qtype, QueryOptions.DNS_QUERY_USE_TCP_ONLY|QueryOptions.DNS_QUERY_BYPASS_CACHE, 0, ref ptr1, 0); 
            if (num1 != 0) 
            {
                if (num1 == 9003)
                {
                    String[] emErrormessage = new string[1];
                    emErrormessage.SetValue("No Record Found",0);
                    return emErrormessage;
                }
                else
                {
                    String[] emErrormessage = new string[1];
                    emErrormessage.SetValue("Error During Query Error Number " + num1 , 0);
                    return emErrormessage;  
                } 
            } 
            for (ptr2 = ptr1; !ptr2.Equals(IntPtr.Zero); ptr2 = rec.pNext) 
            { 
            rec = (DnsRecord) Marshal.PtrToStructure(ptr2, typeof(DnsRecord)); 
            if (rec.wType == (short)qtype) 
            { 
            string text1 = String.Empty; 
            switch(qtype) 
            { 
            case Dns.QueryTypes.DNS_TYPE_A: 
                System.Net.IPAddress ip = new System.Net.IPAddress(rec.a_IpAddress); 
                text1 = ip.ToString(); 
                break; 
                case Dns.QueryTypes.DNS_TYPE_CNAME: 
                text1 = Marshal.PtrToStringAuto(rec.ptr_pNameHost); 
                break; 
                case Dns.QueryTypes.DNS_TYPE_MX: 
                text1 = Marshal.PtrToStringAuto(rec.mx_pNameExchange);
                string[] mxalookup = PAB.DnsUtils.Dns.GetRecords(Marshal.PtrToStringAuto(rec.mx_pNameExchange), "A");
		text1 = text1 + " : " + rec.mx_wPreference.ToString()  + " : " ;
	        foreach (string st in mxalookup)
                {
                    text1 = text1 + st.ToString() + " ";
                }
                
                break; 
                case Dns.QueryTypes.DNS_TYPE_SRV: 
                text1 = Marshal.PtrToStringAuto(rec.srv_pNameTarget); 
                break; 
                case Dns.QueryTypes.DNS_TYPE_PTR:
                text1 = Marshal.PtrToStringAuto(rec.ptr_pNameHost);
                break;
                case Dns.QueryTypes.DNS_TYPE_TEXT:
                    if (Marshal.PtrToStringAuto(rec.data_pStringArray).ToLower().IndexOf("v=spf") == 0)
                    {
                        text1 = Marshal.PtrToStringAuto(rec.data_pStringArray);
                    }
                break; 
            default: 
            continue; 
            } 
            list1.Add(text1); 
            } 
            } 

            DnsRecordListFree(ptr1, 1); 
            return (string[]) list1.ToArray(typeof(string)); 
            } 
            } 
} 

'@
if ($dnsqtype.ToUpper()  -eq "PTR"){
$ipIpaddressSplit = $IpParam.Split(".")
if ($ipIpaddressSplit.length -eq 4){
	$revipaddress = $ipIpaddressSplit.GetValue(3) + "." + $ipIpaddressSplit.GetValue(2) + "." + $ipIpaddressSplit.GetValue(1) + "." + $ipIpaddressSplit.GetValue(0) + ".in-addr.arpa"}
else
	{"Error in IPaddress Format"
}
}
else {
	$revipaddress =  $IpParam
}
Compile-Csharp $code
$qrQueryresults = [PAB.DnsUtils.DNS]::GetRecords($revipaddress,$dnsqtype.ToUpper())
""
foreach ($qresult in $qrQueryresults) {
$qresult
}
""