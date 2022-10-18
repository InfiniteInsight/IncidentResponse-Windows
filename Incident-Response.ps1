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
}

process{
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

function get-loggedOnUsers(){

    $loggedOnUsers = (Get-WMIObject -ClassName Win32_ComputerSystem).Username
    #alternatively use 'query user'
    Return $loggedOnUsers

}

function get-computerUptime{
    $lastBootTime = (Get-WmiObject -ClassName Win32_OperatingSystem).LastBootUpTime
    $currentDate = Get-Date
    $upTime = $currentDate - $lastBootTime
    Return $upTime

}


function get-InitialData(){

    $powershellVersion = $PSVersionTable.PSVersion

    if($powershellVersion.major -lt 5){
        #If the version of powershell present is older than PowerShell 5

        #Get a list of local accounts
        $localUsers = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True"
        $localUsers | make-log
        #Get a list of local Administrators
        $localAdminsGroup = Get-WmiObject -Class Win32_Group -filter "Name='Administrators'"
        $localAdmins = $localAdminsGroup.GetRelated("Win32_UserAccount")
        $localAdmins | make-log
        
        #Get a list of SMB Shares
        $networkShares = Get-WMIObject -Query "SELECT * FROM Win32_Share" | Format-Table
        $networkShares | make-log
    
        #get a list of scheduled tasks
        $scheduledTasks = & schtasks /query /fo LIST /v 
        $scheduledTasks | make-log

    }
    else{
        #If the version of PowerShell installed is 5 or higher

        #Get a list of local accounts and local administrators
        $localUsers = get-localuser | select * 
        $localUsers | make-log
        $localAdmins = get-localgroupmember -group "Administrators" | make-log
        $localAdmins | make-log

        #Get a list of all SMB and NFS file shares
        $networkShares = Get-SMBShare
        $networkShares | make-log
        $nfsShares = Get-FileShare 
        $nfsShares | make-log

        #get a list ofscheduled tasks on the system
        $scheduledTasks = get-scheduledtask
        $scheduledTasks | make-log

        #get run info for scheduled tasks
        $scheduledTaskInfo = $scheduledTasks | get-scheduledtaskinfo
        $scheduledTaskInfo | make-log



    }
    #Execute regardless of version of PowerShell Present:

    get-loggedOnUsers | make-log

    get-computerUptime | make-log

    #Calculate the uptime of the device, moved to a function above
    #$lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    #$currentDate = Get-Date
    #$upTime = $CurrentDate - $lastBoot
    #$upTime | make-log

    #identify logged on users, moved to a function above
    #query user | make-log

    #get list of logged on users including service accounts and system accounts, a little more detailed than the above function. Debating putting this into a function as well.
    $loggedOnUsersAndSysAccounts = Get-WmiObject Win32_LoggedOnUser | Select Antecedent -Unique
    $loggedOnUsersAndSysAccounts | make-log

    #identify all users who have ever logged in
    $usersDirectory = get-childitem  -Directory "c:\users" | select name, CreationTime, LastAccessTime
    $usersDirectory | make-log

    #retrieve hosts file contents
    $hostsFile = get-content "C:\Windows\System32\drivers\etc\hosts" 
    $hostsFile | make-log
    
    #get ARP cache, use arp insteae of get-netneighbor
    $arp = $ arp /a
    $arp | make-log

    #Get IP Routes
    $routes = & route print
    $routes | make-log

    #get processes with parents
    $processes = & wmic get name,parentprocessid,processid
    $processes | make-log

    #get processes and their path
    $processes2 = Get-Process
    foreach($process in $processes2){
        $ wmic process where "ProcessID=$process" get CommandLine | make-log
    }

    #output all listening ports
    $openPorts = & netstat -ano
    $openPorts | make-log

    #get services
    $services = get-service
    $services | make-log

    #find any local shares being hosted on this computer
    $localShares = & net view \\127.0.0.1
    $localShares | make-log

    #export a list of startup items
    $startup = Get-CimInstance Win32_StartupCommand | Select Name, command, Location, User | Format-List 
    $startup | make-log

    #check firewall status
    $firewallStatus = & netsh advfirewall show all state
    $firewallStatus | make-log

    #grab a copy of the registry
    $hklm = & reg export 'HKLM' $dataPath\$incidentName\HKLM-backup.Reg /y
    $hkcu = & reg export 'HKCU' $dataPath\$incidentName\HKCU-backup.Reg /y
    $hkcc = & reg export 'HKCC' $dataPath\$incidentName\HKCC-backup.Reg /y
    $hkcr = & reg export 'HKCR' $dataPath\$incidentName\HKCR-backup.Reg /y
    $hku = & reg export 'HKU' $dataPath\$incidentName\HKU-backup.Reg /y


    #Get windows security event logs
    $securityEvents = Get-WinEvent -logname security -list -asstring
    $securityEvents | out-file $dataPath\$incidentName\Security-Events.log -append    

}



##To do: 
##Capture windows update status
##Get user input for the incident name
##Download and optionally run ProcMon
##Downalod and optionally run Process Explorer
##Download Memoryze
##Download Redline
##Write a description for the entire script, not just make-log

##Capture scheduled tasks -done✅
##Download and run autoruns -done✅
##Capture prefetch files -done✅
##Capture uptime -done✅
##Capture logged in users -done✅
##Capture users who have ever logged in -done✅
##Capture hosts file - done✅
##Capture ARP table - done✅
##Capture netstat -ano connections - done✅
##Get processes - done✅
##Capture ip routes -done✅
##Get services -done✅
##Capture mapped drives -done✅
##check for hosted file shares with net view -done✅
##Get startup list -done✅
##check firewall settings -done✅
##Capture registry hive -done✅
##Pull event logs -done✅