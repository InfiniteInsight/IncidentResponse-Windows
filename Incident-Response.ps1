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
    $startDate | out-file -append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Current Working Directory is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $currentWorkingDirectory.path | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Executed Command is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $executedCommand | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    #$entry | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
}

process{
    <#$startDate | out-file -append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Current Working Directory is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $currentWorkingDirectory.path | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    "Executed Command is:" | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    $executedCommand | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"#>
    $entry | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
}
end{


    $separator = @"
================================================================ {End of entry}
"@
    $separator | out-file -Append -FilePath "$dataPath/$incidentName-Master-Log.txt"
    Write-Host "Item recorded into $incidentName Master Log." -ForegroundColor Green
    Return "0"
}
}


function get-InitialData(){

    #Calculate the uptime of the device
    $lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $currentDate = Get-Date
    $upTime = $CurrentDate - $lastBoot
    $upTime | make-log

    #identify logged on users
    query user | make-log
    #get list of logged on users including service accounts and system accounts
    Get-WmiObject Win32_LoggedOnUser | Select Antecedent -Unique | make-log

    #identify all users who have ever logged in
    get-childitem  -Directory "c:\users" | select name, CreationTime, LastAccessTime | make-log

    #retrieve hosts file contents
    get-content "C:\Windows\System32\drivers\etc\hosts" | make-log
    
    #capture scheduled tasks

    #capture ARP table


}

function get-prefetch(){
    #This will copy all of the files in the prefetch folder and log them to the incident log
    Write-Host "Taking a copy of the Prefetch folder"
    Copy-Item -Recurse -Path "C:\Windows\Prefetch" -Destination $dataPath\Prefetch -Force -PassThru | make-log
    return $null
}

function get-autoruns(){
    Param(
    [Parameter(Mandatory=$false,
    HelpMessage='Specify noStart to $true if you do not want Autoruns to immediately start after download')]
    [ValidateSet($false, $true)]
    $dontAutoStart = $false #by default the "Do not automatically start" parameter is set to false, so autoruns will start as soon as it is downloaded.
)
    #Download the Sysinternals tool Autoruns to the $dataPath (c:\users\public\...)
    $autoRunsPath = "$($dataPath)\Autoruns.exe"
    $URI = "https://live.sysinternals.com/autoruns.exe"

    try{
        if($PSVersionTable.PSVersion.Major -ge "5"){
            Invoke-WebRequest -Uri $URI -OutFile $autoRunsPath 
        }
        else{ 
            (New-Object System.Net.WebClient).DownloadFile($URI,$autoRunsPath)
        }
    }
    catch {
        $Error[0].Exception.GetType()
        write-host " "
        $_
        Write-Host " "
        Write-Host " "
        Write-Warning -Message "There seems to be connectivity issues of some kind."
        Test-Connection -IPv4 -Count 2 -Ping 8.8.8.8
    }
    
    if($dontAutoStart -eq $false){
        if(Test-Path $autoRunsPath){
            #Start autoruns if the downloads were successful
            Start-Process -FilePath $autoRunsPath
        }
    }
    return $null
}

##To do: 
##Capture registry hive
##Capture windows update status
##Capture netstat connections
##Capture ARP table
##Capture ip routes
##Capture mapped drives
##Get user input for the incident name
##Capture scheduled tasks
##Download and run autoruns -done✅
##Capture prefetch files -done✅
##Capture uptime -done✅
##Capture logged in users -done✅
##Capture users who have ever logged in -done✅
##Capture hosts file - done✅
