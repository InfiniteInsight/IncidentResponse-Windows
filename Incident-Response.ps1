### Establishing a folder to write logs to for actions taken, observations made

$myWorkstation = $env:ComputerName #The name of the computer that you are using to assist with Analysis.
$machineBeingInvestigated = $env:COMPUTERNAME #Replace COMPUTERNAME with the name of the endpoint being investigated.
$domain = $env:USERDOMAIN  #obtaining netbios name
$fqdn = $env:USERDNSDOMAIN #fully qualified domain name
$GLOBAL:path = "c:\users\public"
$GLOBAL:dataPath = "$path\$machineBeingInvestigated-$fqdn"

$GLOBAL:incidentName = "TestIncident" ##TO DO: Get user input for the incident name

#new-item -Name $dataPath -Path "\\Path\to\Logging\Location" -ItemType directory
new-item -Name "$machineBeingInvestigated-$fqdn" -Path "$path" -ItemType directory
Start-Transcript -Path "$dataPath\PowerShellTranscript.txt" -append

### Define a function to make writing to that folder easy.
### Each time this function is run it will obtain the date and time and timezone the very moment that the function is run, then it will create a text file containing the entry that 
### you pipe to the function that is clearly dated.

#.DESCRIPTION
#How to use the make-log function: assign your output to a variable, then pass the variable to make-log -entry $variable
#$sample =  get-aduser enevermore
# make-log -entry $sample
# OR Pipe your command directly to make-log
#.EXAMPLE
# get-aduser -filter * | make-log
## currently when you do this with a command that returns multiple objects it will log each object separately.
function make-log(){  ## Possibly change to add-log ?

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $entry
        )
    
    
    begin{
    Write-Host "Begin block"
    $executedCommand = $MyInvocation.line
    #Write-Host "Datapath is $dataPath"
    #Write-Host "entry is $entry"
    $datetime = Get-Date
    $timezone = (Get-TimeZone).DisplayName
    $currentWorkingDirectory = Get-Location
    
    $startDate =@"

================================================================ {Beginning of entry}
$($incidentName) Log entry, date: $datetime $timezone

"@
}

process{
    Write-Host "PRocess block"
    $startDate | out-file -append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Current Working Directory is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $currentWorkingDirectory.path | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Executed Command is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $executedCommand | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $entry | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
}
end{
    $separator = @"
================================================================ {End of entry}
"@
    $separator | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    Write-Host "Item recorded into $incidentName Master Log." -ForegroundColor Green
}
}


function get-InitialData(){

    



}

function get-prefetch(){
    Write-Host "Taking a copy of the Prefetch folder"
    "Taking a copy of the Prefetch folder" | make-log
    Copy-Item -Recurse -Path "C:\Windows\Prefetch" -Destination $dataPath\Prefetch -Force

}

##To do: Capture prefetch file
##Capture registry hive
##Capture uptime
##Capture logged in users
##Capture users who have ever logged in
##Capture update status
##Capture hosts file
##Capture netstat connections
##Capture ARP table
##Capture ip routes
##Capture mapped drives
##Get user input for the incident name
##Capture scheduled tasks
##Download and run anyrun

