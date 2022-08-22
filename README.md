# IncidentResponse-Windows.ps1
This PowerShell script makes available a pipeable function that timestamps a command, logs the command, and captures the output of the command to a file. 

When first executed, this script will create a folder with the fully qualified name of the computer under C:\users\public
A log file with the name of the incident will be created and output from the make-log function will be appended to it with timestamps. 

## make-log

There are two ways to use the make-log function: 

**The first way:**

Assign your output to a variable, then pass the variable to `make-log`
`$example =  get-aduser sampleUser`


`make-log -entry $example`

**The second way, which is the easiest way:**

Simply pipe your command to `make-log`

`get-aduser -filter * | make-log`

Note: currently when you do this with a command that returns multiple objects it will log each object separately.