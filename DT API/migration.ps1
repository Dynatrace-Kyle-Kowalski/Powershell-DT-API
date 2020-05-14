#DT Enironments to be used in migration

<#API FRAME WORK SET UP START#>
#Set API version to be used
$apiversion = 'v1'

#Try to read configs from json file
#\Documents\Code\Powershell
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\environments.json')
    $migrations = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\migration.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}

<#API FRAME WORK SET UP END#>

For ($i=0;$i -lt $migrations.rules.Length;$i++){

    $sEnv = getEnvironment -rule $migrations.rules[$i].sEnv
    $dEnv = getEnvironment -rule $migrations.rules[$i].dEnv

    if($migrations.rules[$i].endpoint -eq "managementZones"){
        migrateMZConfig -rules $migrations.rules[$i] -sEnv $sEnv -dEnv $dEnv 
    }else{
        migrateIDConfig -configEndpoint $migrations.rules[$i].endpoint -configName $migrations.rules[$i].name -sEnv $sEnv -dEnv $dEnv 
    }
}


<#FUNCTIONS LIST
migrateIDConfig ($configEndpoint, $configName, $sEnv, $dEnv){#Migration for rules that utilize a Dynatrace Hash ID
migrateMZConfig ($rules, $sEnv, $dEnv){#Migration for rules for management zones between environments

getEnvironment ($rule){#retrieve which dynatrace environment to be used
function executeRequest ( $request , $method, $headers, $body ){ #Execute api requests
postToDtEnv ($dtEnv, $endpoint, $parameters, $body){#submit new config to Dynatrace environment
putToDTEnv($dtEnv, $endpoint, $parameters, $body){#get Configruation from Dynatrace environment
getFromDTEnv($dtEnv, $endpoint, $parameters){#get Configruation from Dynatrace environment
requestBuilder($endpoint, $parameters, $environment){#build string based on variables for script flexibility
changeEnvironment ($mzConfig, $sEnv, $dEnv) {#Change environment tag 
cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
#>

function migrateMZConfig ($rules, $sEnv, $dEnv){#Migration for rules for management zones between environments
    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint 'managementZones'
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv  -endpoint ('managementZones' + '/' + (getIdValue -apiResponse $sourceResponse -name ($rules.name + ' - ' + $rules.sEnv.ToUpper())))     
    }catch{
        Write-Host "Source Get Error - MZ"
        BREAK
    }

    try{
        #Get json element to search for config ID
        $destResponse = getFromDTEnv -dtEnv $dEnv -endpoint 'managementZones'
        #get ID from Destination system to update config of same name to Source
        $destID = getIdValue -apiResponse $destResponse -name ($rules.name + ' - ' + $rules.dEnv.ToUpper())
    }catch{
        Write-Host "Destination Get Error"
        BREAK
    }
    
    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse

    $cleanBody = changeEnvironment -mzConfig $cleanBody -sEnv $rules.sEnv -dEnv $rules.dEnv
    $cleanBody.name = ($rules.name + ' - ' + $rules.dEnv.ToUpper())

    try{
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ('managementZones' + '/' + $destID)
        }else{#create new configuration 
            postToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ('managementZones')
        }
    }catch{
        Write-Host "Submission Error"
    }
    
}

function migrateIDConfig ($configEndpoint, $configName, $sEnv, $dEnv){#Migration for rules that utilize a Dynatrace Hash ID
    $sourceResponse = $null
    $destResponse = $null
    $destID = $null
    $cleanBody = $null

    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint $configEndpoint
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))     
    }catch{
        Write-Host "Source Get Error" + $sourceResponse
        BREAK
    }

    try{
        #Get json element to search for config ID
        $destResponse = getFromDTEnv -dtEnv $dEnv  -endpoint $configEndpoint
        #get ID from Destination system to update config of same name to Source
        $destID = getIdValue -apiResponse $destResponse -name $configName
    }catch{
        Write-Host "Destination Get Error" + $destResponse
        BREAK
    }

    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse
    try{
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ($configEndpoint + '/' + $destID)
        }else{#create new configuration 
            postToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ($configEndpoint)
        }
    }catch{
        Write-Host "Submission Error"
    }
    
}

function getEnvironment ($rule){#retrieve which dynatrace environment to be used
    if($rule -ieq "Prod"){
        return $environments.prod
    }elseif ($rule -eq "DTTesting"){
        return $environments.testing
    }else{
        return $environments.nonProd
    }
}

function executeRequest ( $request , $method, $headers, $body ){ #Execute api requests
    #Write-Host $request
    if($body){ #check for body which should be a powershell object
        $body = ConvertTo-Json -depth 24 -InputObject $body
    }
    Invoke-RestMethod $request -Method $method -Headers $headers -Body $body   
} 

function postToDtEnv ($dtEnv, $endpoint, $parameters, $body){#submit new config to Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder  -environment $dtEnv -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder  -environment $dtEnv -endpoint $endpoint -parameters $parameters
    }

    #Add HTTP Headders
    $requestHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $requestHeaders.Add("Authorization", "Api-Token "+ $dtEnv.APIToken)
    $requestHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    $return = executeRequest -request $builtRequest -method 'POST' -headers $requestHeaders -body $body
    #header clean up
    $requestHeaders.remove("Content-Type")
    $requestHeaders.remove("Authorization")
    return $return
}

function putToDTEnv($dtEnv, $endpoint, $parameters, $body){#get Configruation from Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -parameters $parameters
    }

    #Add Headers
    $requestHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $requestHeaders.Add("Authorization", "Api-Token "+ $dtEnv.APIToken)
    $requestHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    $return = executeRequest -request $builtRequest -method 'PUT' -headers $requestHeaders -body $body
    #header clean up
    $requestHeaders.remove("Content-Type")
    $requestHeaders.remove("Authorization")
    return $return
}

function getFromDTEnv($dtEnv, $endpoint, $parameters){#get Configruation from Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -parameters $parameters
    }
    #Add Headers
    $requestHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $requestHeaders.Add("Authorization", "Api-Token "+ $dtEnv.APIToken)
    #Execute request against API
    $return = executeRequest -request $builtRequest -method 'GET' -headers $requestHeaders
    #header clean up
    #$requestHeaders.remove("Authorization")
    return $return
}

function requestBuilder($endpoint, $parameters, $environment){#build string based on variables for script flexibility
    
    if($environment.isDTManaged -ieq "True"){
        if (!$parameters){
            'https://' + $environment.Domain + '/e/' + $environment.Environment + '/api/config/' + $apiversion + $endpoint
        }else {
            'https://' + $environment.Domain + '/e/' + $environment.Environment + '/api/config/' + $apiversion + $endpoint + "?" + $parameters
        }
    }else{
        if (!$parameters){
            'https://' + $environment.Environment + '.' + $environment.Domain + '/api/config/' + $apiversion  + $endpoint
        }else {
            'https://' + $environment.Environment + '.' + $environment.Domain + '/api/config/' + $apiversion + $endpoint + "?" + $parameters
        }
    }
}
function changeEnvironment ($mzConfig, $sEnv, $dEnv) {#Change environment tag 
    #I'm sure there is a better way to do this but I don't know PS well enough
    For($i=0;$i -lt $mzConfig.rules.Length; $i++){
        For($j=0;$j -lt $mzConfig.rules[$i].conditions.Length;$j++){
            if($mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value -ieq $sEnv){
                $mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value = $dEnv
            }
        }
    }
    $mzConfig
}
function cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
    $dirtyResponse.psobject.properties.remove('metadata')
    $dirtyResponse.psobject.properties.remove('id')
    $dirtyResponse
}

function getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $idReturn = $apiResponse.values | Where-Object {$_.name -eq $name}
    $idReturn.id
}