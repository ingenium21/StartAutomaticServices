# Varibles used to caluclate number and type of errors if any. 
[int]$successfulRestart = 0 
[int]$failedRestart = 0 
[int]$ResultTotal = 0 

# List of Services to Ignore. 
$Ignore=@( 
    'Microsoft .NET Framework NGEN v4.0.30319_X64', 
    'Microsoft .NET Framework NGEN v4.0.30319_X86', 
    'Multimedia Class Scheduler', 
    'Performance Logs and Alerts', 
    'SBSD Security Center Service', 
    'Shell Hardware Detection', 
    'Software Protection',
    'Chromium Update Service (chromium)',
    'Microsoft Edge Update Service (edgeupdate)',
    'Group Policy Client',
    'Google Update Service (gupdate)',
    'Downloaded Maps Manager',
    'Origin Web Helper Service',
    'Windows Image Acquisition (WIA)',
    'TPM Base Services'; 
) 

#Get a list of automatic services that aren't running and that aren't part of the above ignore group
$services = Get-CimInstance Win32_Service | Where-Object {$_.StartMode -eq 'Auto' -and $Ignore -notcontains $_.DisplayName -and $_.State -ne 'Running'}

#if Services is not empty
if ($services) {
    foreach ($service in $services){
        $service | start-service #start the servie

        Start-Sleep -s 5 #pause for 5 seconds

        $StoppedService = Get-Service -DisplayName $service.DisplayName
        if ($StoppedService.Status -ne 'Running') {
            #set the error level to 2 (critical)
            $failedRestart = 2
            # If this is not the first recorded error amend the error text 
            if ($strFailedRestart) {
                $strFailedRestart += "{0}`n" -f $Service.Displayname
            }
            #$if this is the first or only error set error text
            Else {
                $strResultError = "Services failed after restart: {0}`n" -f $Service.Displayname 
            }
        }
        else {
            # If the service restarted set the warning error level to 1 (warning) 
            $successfulRestart = 1 
            # If this is not the first recorded error amend the error text 
            if ($strSuccessfulRestart) { 
            $strSuccessfulRestart=$strSuccessfulRestart + ', ' + $Service.Displayname 
            } 
            # If this is the first or only error set error text 
            ELSE { 
                $strSuccessfulRestart = 'Services restarted: ' + $Service.Displayname 
            }
        }
    }
    # Clear the StoppedService varible 
    if ($StoppedService) {
        Clear-Variable StoppedService
    }
}
# Add the warning error (0 or 1) to the critical error (0 or 2) 
$ResultTotal=$successfulRestart + $failedRestart 
 
# Using the sum of the warning errors to the critical errors select the appropriate response 
Switch ($intResultTotal) { 
    # Default/no errors 
    default { 
        write-host 'All automatic started services are running' 
        exit 0 
    } 
    # Warning error(s) only 
    1 { 
        write-host $strResultWarning 
        exit 1 
    } 
    # Critical error(s) only 
    2 { 
        write-host $strResultError 
        exit 2 
    }  
    # Critical and Warning errors 
    3 { 
        write-host $strResultError 
        write-host $strResultWarning 
        exit 2 
    }  
}