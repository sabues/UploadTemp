# By Daniel Seveso 5/6/2013
# PowerShell 3.0 only due to ConverFrom-Json change
#
# Script that queries my 3M-50 Wi-Fi Thermostat and set various parameters of the thermostat

# TODO: Control execution path and make sure to find utlis.ps1
# TODO: Include a debug function. In progress ...
# TODO: Review debug logging and tracing function

param (
    [switch] $Debug, 
    [string] $TName=$(throw "USAGE: Set-Thermostat [-TName] <thermostat name or IP address> [-Mode <Auto|Off|Heat|Cool>] [-BaseFilename <logfilename>] "),
    [string] $Mode,
    [string] $BaseFileName="setThermostat.log")

# Include utils function
. .\utils.ps1

# Invoke log file initialization
initlogfile $BaseFileName 100000 "Date,EventType,Activity,Status"

if ($debug) {DebugOut Info Init,"Set-HouseTemp Started"}

# Check if we're running PoweShell 3
checkonPS3

# Function:     getyahoowheather
# Arguments:    None, Assumes Arlington area: w=12790864&u=f
# Purpose:      get Yahoo weather RSS
#

function getyahoowheather {
$url="http://weather.yahooapis.com/forecastrss?w=12790864&u=f"
if ($debug) {DebugOut Info Main,"Connecting to Yahoo Weather on $url"}
Try {
     $feed=[xml](new-object system.net.webclient).downloadstring($url)
     if ($debug) {DebugOut Info Main,"Outside Temp read $outsideTemp"}
     }
 Catch {
     $downloaderror = $error[0]
     DebugOut Error Yahoo,$downloaderror.Exception
     ErrOut $downloaderror Yahoo
     $feed = $null
     }
$feed
}

# Function:     connectTS
# Arguments:    url : complete url with the command to the thermostat
# Purpose:      Sends commands to the thermostat, log any errors and handle retry logic
# Returns:      $global:tstatOutput
function connectTS ([string]$url, [string]$b, [string]$m) {
    $tmethods = {'Default', 'Delete', 'Get', 'Head', 'Options', 'Post', 'Put', 'Trace'}
    $tmethods.GetType()
    if ($tmethods -contains $m)
    {'true'}
    else 
    {'false'}
    }

connectTS ds ds Post


    Try {      
        $s= Invoke-RestMethod $url
         }
     Catch {
         $downloaderror = $error[0]
         $downloaderror.Exception
         DebugOut Error Thermostat,$downloaderror.Exception
         ErrOut $downloaderror Thermostat
         $insideTemp = "Error"
         break
         }
     $global:tstatOutput = $s
}      


$url='http://192.168.1.76/tstat/led'
getTS $url
"Livingroom insideTemp = " + $tstatOutput.temp




# Set the temperature mode to HEAT (tmode=1) - TESTING...
$s= @{"energy_led"=0} |ConvertTo-Json
$s
 Try {
     $u = $null
     $u = Invoke-RestMethod $url -Body $s -Method post -Verbose
     $u.success
     }
 Catch {
     $uploaderror = $error[0]
     $uploaderror.Exception
     DebugOut Error Thermostat,$uploaderror.Exception
     ErrOut $uploaderror Thermostat
     break
     }




     

## Main Loop
#while(1)
#{
#   " "   
#   $tempdate = Get-Date -Format G
#   "Time: $tempdate"
#   
#         
#   # 3M-50 temp
#   # json output
#   # -----------
#   #  temp       Temperature
#   #  tmode      Thermostat operating mode 0: OFF 1: HEAT 2: COOL 3: AUTO
#   #  fmode      Fan operating mode 0: AUTO 1: AUTO/CIRCULATE 2: ON 
#   #  override   Override status 0: Override is disabled 1: Override is enabled. 
#   #             Note: Firmware versions prior to 1.04 can return any non-zero 
#   #  hold       Target temperature Hold status 0: Hold is disabled 1: Hold is enabled 
#   #  t_heat     
#   #  tstate     HVAC Operating State  0: OFF 1: HEAT 2: COOL 
#   #             Note: This functionality may not be available in all models
#   #  fstate     Fan Operating State 0: OFF 1: ON 
#   #             Note: Only available with CT-30
#   #  time       @{day=0; hour=7; minute=51}
#   #             JSON object with the following fields: day, hours, minutes.  day : Integer value representing the day of the week, with day 0 being Monday. hour : Integer value representing number of hours elapsed since midnight. minutes : Integer value representing number of minutes since start of the hour. 
#
#   #  t_type_post
#   #             Target Temperature POST type. Integer value that indicates whether a POST on t_heat/t_cool will result in temporary or absolute temperature change. 
#   #             0: Temporary Target Temperature 1: Absolute Target Temperature 2: Unknown 
#   #             This attribute is deprecated and will be obsoleted in future versions of the API
#
#
#   # Thermostat loop
#   do {
#    $url="http://192.168.1.76/tstat/"
#    #$url="http://1.1.1.1/tstat/" #introduce error connecting to the thermostat
#    $client = new-object net.webclient
#    $s = $null
#    #introducing delay to facilitate retries with the slow thermostat.
#    # Start-Sleep -s (5)
#    Try {
#        $s = $client.DownloadString($url)
#        }
#    Catch {
#        $downloaderror = $error[0]
#        $downloaderror.Exception
#        DebugOut Error Thermostat,$downloaderror.Exception
#        ErrOut $downloaderror Thermostat
#        $insideTemp = "Error"
#        break
#        }
#    $tstatOutput = $s | ConvertFrom-Json
#    $insideTemp = $tstatOutput.temp
#    "Livingroom insideTemp = " + $insideTemp
#    }           
#   while ((!$s) -or ($insideTemp -eq -1))
#   
#
#
#   if (!$nocpu){
#   #CPU temp of the computer running this script (Note: this should run as Administrator)
#       Try {
#            $cputemp=Get-WmiObject msacpi_thermalzonetemperature -Namespace "root\wmi"
#            $cputempvalueF=$cputemp.currenttemperature / 10 *9 /5 - 459.67
#            }
#       Catch {
#            $downloaderror = $error[0]
#            $downloaderror.Exception
#            $cputempvalueF = "Error"
#            }
#       "CPU Temperature = " + $cputempvalueF
#   }
#
#   # Add data to the CSV output file
#   # Columns:
#   # $tempdate:      Date 
#   # $outsideTemp    Outside Temperature
#   # $insideTemp     Inside Temperature
#   # $cputempvalueF  CPU Temperature
#   # $s              Raw data from Thermostat
#   $templine="$tempdate,$outsideTemp,$insideTemp,$cputempvalueF,$s"
#   checkoutfile $csvoutfile $csvoutfilesize
#   
#   # Write line to the CSV Output file
#   $templine | Add-Content -Path .\$csvoutfile
#
#   # thingspeak (turn off in the meantime to avoid conflict with the one running)
#   #$url="http://api.thingspeak.com/update?key=*KEY*&field1=$insideTemp&field2=$outsideTemp&field3=$cputempvalueF"
#   #$client = new-object net.webclient
#   #Try {
#   #    $s = $client.DownloadString($url)
#   #     }
#   #Catch {
#   #    $downloaderror = $error[0]
#   #    $downloaderror.Exception
#   #    DebugOut Error Thingspeak,$downloaderror.Exception
#   #    ErrOut $downloaderror Thingspeak
#   #    }
#
#
#   # Sampling interval
#   #Start-Sleep -s (60*5)
#   Start-Sleep -s (5)
#}

