# Module        utils.ps1
# Created       [4/25/2013]
# Author:       Daniel Seveso
# Purpose:      Provide general tracing and logging mechanisms 
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# TODO: parametrize output file definition
# TODO: Create codes/constants for de debug event types. Mimics Eventlog codes ?
# TODO: This function needs to be fixed for the log file / Build generic function useful for log and output file.


# Function:     DebugOut
# Arguments:    Event,
#               Arguments -> "EventType,Activity,Status,RawData"
# Purpose:      Output an list with specified name, should only be used when $DEBUG -eq $true
#
function DebugOut([string] $Event=$(throw "USAGE: DebugOut [-Event] <string> [[-Arguments] <array>]"), [array]$Arguments = @())
{
    $fileoutdate = Get-Date -Format G
    $logline = "$fileoutdate,$Event"
    for($i=0; $i -lt $Arguments.length; $i ++)
    {
        $logline=$logline + "," + $Arguments[$i]
    }
    $logline | Add-Content -Path .\$logoutfile
}


# Function:     initlogfile
# Arguments:    filename : file will have a name of "COMPUTERNAME-FILENAME.LOG" backup files adds its timestamp
#               filesize : maximum size in bytes
# Purpose:      Initialize log file for errors and debug output
#
function initlogfile ([string] $filename = "myTemp", [int] $logoutfilesize = 100000, [string] $loglineheader) {
    $global:logoutfile = "$env:COMPUTERNAME-$filename.log"
    # Write header line each time the script restarts
    if ($debug) {DebugOut Info initlogfile,"Initializing $global:logoutfile"}
    $loglineheader | Add-Content -Path .\$global:logoutfile
}



# TODO: This function needs to be fixed for the log file / Build generic function useful for log and output file.
# Output file size control and rename function
function checkoutfile ($file,$csvsizelimit) {
    DebugOut Info checkoutfile,"Entering checkoutfile..."
    $csvoutdate = Get-Date -Format "yyMMddhhmmss"
    $csvoutsize = (Get-ChildItem .\$file).Length
    if ($csvoutsize -ge $csvsizelimit) {
        Rename-Item .\$file .\$file-$csvoutdate.csv
        $templineheader | Add-Content -Path .\$file
        }
    DebugOut Info checkoutfile,"Just checked the file... $file for size under $csvsizelimit"
}



# Function:     ErrOut
# Arguments:    ErrorEvent (ErrorRecord), Activity
# Purpose:      Writes information of the error record to the log output file
#
function ErrOut([System.Management.Automation.ErrorRecord] $ErrEvent=$(throw "USAGE: DebugOut [-ErrEvent] <ErrorRecord>"), $Arguments)
{
    $fileoutdate = Get-Date -Format G
    $logline = "$fileoutdate,Error,$Arguments,$ErrEvent.Exception in $ErrEvent.ScriptStackTrace"
    $logline | Add-Content -Path .\$logoutfile
}

# Function:     checkonPS3
# Arguments:    
# Purpose:      Check if we're running PoweShell 3
function checkonPS3 {
    $psVersion = $host.Version.Major
    if ($psVersion -lt 3) {
        Write-Host "ERROR: This script requires PowerShell version 3" -ForegroundColor Red
        try {throw (New-Object System.ApplicationException)}
        catch {
            if ($debug) {DebugOut Error PowerShell,"Version: $psVersion Required: 3.x"}
            ErrOut $Error[0] "Version: $psVersion Required: 3"
        exit
        }
    }
} 
#------------------------------------------------------