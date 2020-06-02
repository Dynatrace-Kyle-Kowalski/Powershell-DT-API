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



#get audit log from DT environment
$log = getFromDTEnv -dtEnv $sEnv -endpoint '/auditlogs' -parameters 'pageSize=5000&from=-30d&to=now&sort=-timestamp' -api 'enviornment'
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


#TODO - Do something

Write-Host $auditList

