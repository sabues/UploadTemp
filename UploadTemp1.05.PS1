# By Daniel Seveso 3/1/2013
#
# Built up on work by David Mohorn - 07/04/2011
# This is a simple script that queries my 3M-50 Wi-Fi Thermostat and grabs the room temperature.
# It also goes to Yahoo Weather and gets the outside temperature for my area.
# This data is then posted to ThingSpeak.com.


# Version without the CPU temp for those machines that don't support it. 
# TODO: include a switch for this variant. Done 4/2/2012 (-nocpu:$true)
# TODO: include size managemente and header for CSV output. Done 4/3/2013
# TODO: How to launch @ startup as administrator
# TODO: Check the thermostat returns a good value (not -1). Done 4/2/2013
# TODO: Add target temp and if thermostat is turned on or not to the CSV file
# TODO: Include a debug function


# $nocpu will dictate if we include WMI to check on CPU temp using msacpi_thermalzonetemperature
param($nocpu=$false,$logenabled=$false)


# Temperature Output file 
$csvoutfile = "$env:COMPUTERNAME-myTemp.csv"
$csvoutfilesize = 10000 #bytes
$templineheader="Date,OutsideTemp,InsideTemp,CPUTemp,RawData"
# Write header line each time the script restarts
$templineheader | Add-Content -Path .\$csvoutfile


# Log Output file 
$logoutfile = "$env:COMPUTERNAME-myTemp.log"
$logoutfilesize = 10000 #bytes
$loglineheader="Date,OutsideTemp,InsideTemp,CPUTemp,RawData"
# Write header line each time the script restarts
$loglineheader | Add-Content -Path .\$logoutfile


# Output file size control and rename function
function checkoutfile ($file,$csvsizelimit) {
Write-Output "Just checked the file... $file for size under $csvsizelimit"
$csvoutdate = Get-Date -Format "yymmddhhmmss"
$csvoutsize = (Get-ChildItem .\$file).Length
if ($csvoutsize -ge $csvsizelimit) {
    Rename-Item .\$file .\$file-$csvoutdate.csv
    $templineheader | Add-Content -Path .\$file
    }
}

# Main Loop
while(1)
{
   " "   
   $tempdate = Get-Date -Format G
   "Time: $tempdate"
   
   # get Yahoo weather RSS
   $feed=[xml](new-object system.net.webclient).downloadstring("http://weather.yahooapis.com/forecastrss?w=12790864&u=f")
   $outsideTemp = $feed.rss.channel.Item.condition.temp    
   "Yahoo outsideTemp = " + $outsideTemp
         
   # 3M-50 temp
   do {
    #$url="http://192.168.1.76/tstat/"
    $url="http://1.1.1.1/tstat/"
    $client = new-object net.webclient
    $s = $null
    #introducing delay to facilitate retries with the slow thermostat.
    Start-Sleep -s (5)
    $s = $client.DownloadString($url)
    $s
    write-host "passed the connection statement"    
    $hash = $s -replace '{|}|"' -replace ",","`n" -replace ":","=" | ConvertFrom-StringData
    "Livingroom insideTemp = " + $hash["temp"]            
    $insideTemp = $hash["temp"]  } 
   #while ((!$s) -or ($insideTemp -eq -1))
   while (($s) -or ($insideTemp -eq -1))
   


   if (!$nocpu){
   #CPU temp of the computer running this script (Note: this should run as Administrator)
   $cputemp=Get-WmiObject msacpi_thermalzonetemperature -Namespace "root\wmi"
   $cputempvalueF=$cputemp.currenttemperature / 10 *9 /5 - 459.67
   "CPU Temperature = " + $cputempvalueF
   }

   # Added raw data from the sensor to the CSV file for debugging purposes
   $templine="$tempdate,$outsideTemp,$insideTemp,$cputempvalueF,$s"
   checkoutfile $csvoutfile $csvoutfilesize
   $templine | Add-Content -Path .\$csvoutfile

   # thingspeak (turn off in the meantime to avoid conflict with the one running)
   #$url="http://api.thingspeak.com/update?key=*KEY*&field1=$insideTemp&field2=$outsideTemp&field3=$cputempvalueF"
   #$client = new-object net.webclient
   #$s = $client.DownloadString($url)

   # Sampling interval
   #Start-Sleep -s (60*5)
   Start-Sleep -s (5)
}

