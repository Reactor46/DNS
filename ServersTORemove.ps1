Get-Content C:\LazyWinAdmin\DNS\Systems.txt | 
 ForEach { if (test-connection $_ -quiet) { write-output "$_" | Out-File C:\LazyWinAdmin\DNS\Systems-Alive.txt -append utf8
  } else { 
  write-output "$_" | Out-File C:\LazyWinAdmin\DNS\Systems-Dead.txt -append utf8}}
