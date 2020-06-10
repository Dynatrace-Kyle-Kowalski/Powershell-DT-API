#Path to project
$path = '.\DT API'
#DT Enironments to be used in migration
. $path'\core\dtCore.ps1'

#Try to read configs from json file
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $path'\Configs\environments.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
<#API FRAME WORK SET UP END#>


#Set environment to be used
if($audit.environment -ieq "Prod"){
    $sEnv = $environments.prod
}elseif ($rule -eq "DTTesting"){
    $sEnv = $environments.testing
}else{
    $sEnv = $environments.nonProd
}

$sEnv = $environments.nonProd

function convertEpoch ($timestamp){#Convert Timestamp to Date-Time object
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $origin.AddMilliseconds($timestamp)
}


#script start

#get audit log from DT environment
$log = getFromDTEnv -dtEnv $sEnv -endpoint '/auditlogs' -parameters 'pageSize=5000&from=-30d&to=now&sort=timestamp' -api 'enviornment'
#create running list of Audit Log to parse
$auditList = $log.auditlogs
#set variable to be used in next parameter call
$nextPageKey = $log.nextPageKey

while ($log.nextPageKey)
{
    $log = getFromDTEnv -dtEnv $sEnv -endpoint '/auditlogs' -parameters "nextPageKey=$nextPageKey&pageSize=5000&from=-30d&to=now&sort=-timestamp" -api 'enviornment'
    #add to list and update nextPageKey for new page
    $auditList += $log.auditlogs
    $nextPageKey = $log.nextPageKey
}

$folder = Get-Date -Format "MMddyyyy-HHmm"
if (-not (Test-Path -Path "$path\Output\$folder")){#check if backups directory exisits if not create
    New-Item -Path "$path\Output\" -Name $folder -ItemType "Directory"
}
#File Set up
New-Item -Path "$path\Output\$folder" -Name "AccessLog.csv" -ItemType "File" 
Add-Content -Path "$path\Output\$folder\AccessLog.csv" -Value '"UserName","Timestamp"'
#File Setup
New-Item -Path "$path\Output\$folder" -Name "ConfigLog.csv" -ItemType "File" 
Add-Content -Path "$path\Output\$folder\ConfigLog.csv" -Value '"UserName","Timestamp","Event Type","Entity","Log ID"'

for ($i=0;$i -lt $auditList.Length; $i++){
    if($auditList[$i].userOrigin -ine "system"){
        if($auditList[$i].eventType -ieq "LOGIN"){
                #build csv line
                Add-Content -Path "$path\Output\$folder\AccessLog.csv" -Value ($auditList[$i].user + "," + (Get-Date -Date (convertEpoch -timestamp $auditList[$i].timestamp) -Format "MM/dd/yyyy HH:mm"))
            }else{
                #build csv line
                $date = convertEpoch -timestamp $auditList[$i].timestamp
                Add-Content -Path "$path\Output\$folder\ConfigLog.csv" -Value ($auditList[$i].user + "," + (Get-Date -Date ($date) -Format "MM/dd/yyyy HH:mm") +','+ $auditList[$i].eventType + ',' + $auditList[$i].entityId + ',' + $auditList[$i].logId)
            }
    }
    
}

$auditList = ConvertTo-Json -Depth 24 -InputObject $auditList
New-Item -Path "$path\Output\$folder" -Name "AuditLogOutput.json" -ItemType "File" -Value $auditList



<#
$folder = Get-Date -Format "MMddyyyy-HHmm"
if (-not (Test-Path -Path "$path\Output\$folder")){#check if backups directory exisits if not create
    New-Item -Path "$path\Output\" -Name $folder -ItemType "Directory"
}
New-Item -Path "$path\Output\$folder" -Name "AccessLog.csv" -ItemType "File" 
New-Item -Path "$path\Output\$folder" -Name "ConfigLog.csv" -ItemType "File" 

create and writeAccessLog
New-Item -Path "$path\Output\$folder" -Name "AccessLog.csv" -ItemType "File" 
for ($i=0;$i -lt $accessLog.Length; $i++){
     Add-Content -Path "$path\Output\$folder\AccessLog.csv" -Value $accessLog[$i] 
}

New-Item -Path "$path\Output\$folder" -Name "ConfigLog.csv" -ItemType "File" 
for ($i=0;$i -lt $configLog.Length; $i++){
     Add-Content -Path "$path\Output\$folder\ConfigLog.csv" -Value $configLog[$i] 
}
#>


