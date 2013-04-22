$s = $null
#$url="http://192.168.1.76/tstat/"
$url="http://192.168.1.76/sys/"
$client = new-object net.webclient
$s = $client.DownloadString($url)
$cThermOut = $s | ConvertFrom-Json
$s
$cThermOut

write-host "passed the connection statement"    
#$hash = $s -replace '{|}|"' -replace ",","`n" -replace ":","=" | ConvertFrom-StringData

#"Livingroom insideTemp = " + $hash["temp"]            
#$insideTemp = $hash["temp"]  } 
