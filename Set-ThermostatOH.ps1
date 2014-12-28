# By Daniel Seveso 5/6/2013
# PowerShell 3.0 only due to ConverFrom-Json change
#
# Script that queries my 3M-50 Wi-Fi Thermostat and set various parameters of the thermostat for use by the exec binding on OpenHAB

# TODO: Control execution path and make sure to find utlis.ps1
# TODO: Include a debug function. In progress ...
# TODO: Review debug logging and tracing function

param (
    [String] $TName=$(throw "USAGE: Set-Thermostat [-TName] <thermostat name or IP address> -Mode <Auto|Off|Heat|Cool> [-TargetTemp <temp F>]"),
    [String] $Mode=$(throw "USAGE: Set-Thermostat [-TName] <thermostat name or IP address> -Mode <Auto|Off|Heat|Cool> [-TargetTemp <temp F>]"),
    [Double] $TargetTemp = $null
    )

$logdate = Get-Date -Format G
$logfile = ".\logs\set-ThermostatOH.log"

if (!$TargetTemp -and (($Mode -like "Auto") -or ($Mode -like "Heat") -or ($Mode -like "Cool"))) {
    "$logdate :Auto, Heat or Cool without TargetTemp" | Add-Content $logfile
    break
    } 


# Define the body of the post request
switch ($Mode){
    Auto {$s= @{"tmode"=3} }
    Off  {$s= @{"tmode"=0} }
    Heat {$s= @{"tmode"=1} }
    Cool {$s= @{"tmode"=2} }
    default {"$logdate :Wrong Thermostat mode $Mode" | Add-Content $logfile
    break
    }
}

# Check if target temperature exists in the expected modes
if ($TargetTemp -and (($Mode -like "Auto") -or ($Mode -like "Heat") -or ($Mode -like "Cool"))) {
    if ($Mode -like "Heat"){
        $s = $s + @{"it_heat" = $TargetTemp}
        }
    elseif ($Mode -like "Cool"){
        $s = $s + @{"it_cool" = $TargetTemp}
        }
    elseif ($Mode -like "Auto"){
        $s = $s + @{"it_cool" = $TargetTemp}
        }
} 

# Thermostat url 'http://192.168.1.76/tstat'
$url='http://' + $tname + '/tstat'


# Set the temperature mode to HEAT (tmode=1) - TESTING...

$b= $s |ConvertTo-Json

# Send command to thermostat
Try {
     $u = $null
     $u = Invoke-RestMethod $url -Body $b -Method post
     $logdate + " Invoke-RestMethod result: " + $u.success | Add-Content $logfile
     }
Catch {
     $uploaderror = $error[0]
     "$logdate $uploaderror.Exception upload error" | Add-Content $logfile
     break
     }




     

