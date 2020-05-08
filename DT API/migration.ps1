#Endpoint to be used for migration
#$config = 'autoTags'
#Name of the config to be moved
$configName = 'MIGRATION'

<#API FRAME WORK SET UP START#>
#Set API version to be used
$apiversion = 'v1'

#Try to read configs from json file
try{
    $fileParameters = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\environments.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
#Set DT managed flag for Request builder
if ($fileParameters.isDTManaged -eq "False"){
    $isManaged = $FALSE
}else{
    $isManaged = $TRUE
}
#Set up Source
$sourceDTEnvironment = $fileParameters.source.Environment
$sourceDomain = $fileParameters.source.Domain
$sourceToken = $fileParameters.source.APIToken
$sourceMZPostfix = $fileParameters.source.MZPostfix
#Set up Destination
$destDTEnvironment = $fileParameters.destination.Environment
$destDomain = $fileParameters.destination.Domain
$destToken = $fileParameters.destination.APIToken
$destMZPostfix = $fileParameters.destination.MZPostfix

#Create Header Object for request to use certian objects may add to this header
$sourceHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$sourceHeaders.Add("Authorization", "Api-Token "+ $sourceToken)

#Create Header Object for request to use certian objects may add to this header
$destHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$destHeaders.Add("Authorization", "Api-Token "+ $destToken)
<#API FRAME WORK SET UP END#>

#migrateIDConfig -configEndpoint $config -configName $configName 

migrateMZConfig -configEndpoint 'managementZones' -configName 'Template'

<#FUNCTIONS LIST
migrateIDConfig ($configEndpoint, $configName)
executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
getFromSource( $endpoint, $parameters)
putToSource( $endpoint, $parameters, $body)
getFromDest ($endpoint, $parameters)
putToDest ($endpoint, $parameters, $body)
cleanMetaData ($dirtyResponse)
#>

function migrateMZConfig ($configEndpoint, $configName){#Migration for rules that utilize a Dynatrace Hash ID
    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromSource -endpoint $configEndpoint
        #Get json element for config
        $sourceResponse = getFromSource -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))     
    }catch{
        Write-Host "Source Get Error"
        BREAK
    }

    try{
        <# 
        destID would have strange implications migrating a MZ within the same DT environment 
        #>
        #Get json element to search for config ID
        $destResponse = getFromDest -endpoint $configEndpoint
        #get ID from Destination system to update config of same name to Source
        #$destID = getIdValue -apiResponse $destResponse -name $configName
    }catch{
        Write-Host "Destination Get Error"
        BREAK
    }
    
    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse

    $cleanBody = changeEnvironment -mzConfig $cleanBody -sEnv $sourceMZPostfix -dEnv $destMZPostfix


    try{
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDest -body $cleanBody -endpoint ($configEndpoint + '/' + $destID)
        }else{#create new configuration 
            postToDest -body $cleanBody -endpoint ($configEndpoint)
        }
    }catch{
        Write-Host "Submission Error"
    }
    
}

function changeEnvironment ($mzConfig, $sEnv, $dEnv) {#Change environment tag 
    #I'm sure there is a better way to do this but I don't know PS well enough
    For($i=0;$i -lt $mzConfig.rules.Length; $i++){
        For($j=0;$j -lt $mzConfig.rules[$i].conditions.Length;$j++){
            if($mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value -eq $sEnv){
                $mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value = $dEnv
            }
        }
    }
    $mzConfig
}

function migrateIDConfig ($configEndpoint, $configName){#Migration for rules that utilize a Dynatrace Hash ID
    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromSource -endpoint $configEndpoint
        #Get json element for config
        $sourceResponse = getFromSource -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))     
    }catch{
        Write-Host "Source Get Error"
        BREAK
    }

    try{
        #Get json element to search for config ID
        $destResponse = getFromDest -endpoint $configEndpoint
        #get ID from Destination system to update config of same name to Source
        $destID = getIdValue -apiResponse $destResponse -name $configName
    }catch{
        Write-Host "Destination Get Error"
        BREAK
    }

    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse
    try{
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDest -body $cleanBody -endpoint ($configEndpoint + '/' + $destID)
        }else{#create new configuration 
            postToDest -body $cleanBody -endpoint ($configEndpoint)
        }
    }catch{
        Write-Host "Submission Error"
    }
    
}


function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
    #Write-Host $request
    if($body){ #check for body which should be a powershell object
        $body = ConvertTo-Json -depth 24 -InputObject $body
    }
    Invoke-RestMethod $request -Method $method -Headers $headers -Body $body   
} 

function getFromDest ($endpoint, $parameters){#submit config to new environment
    if (!$parameters)
    {
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Execute request against API
    executeRequest -request $builtRequest -method 'GET' -headers $destHeaders 
}

function putToDest ($endpoint, $parameters, $body){#submit config to new environment
    if (!$parameters){
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Add Content-Type Header for API parsing
    $destHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    executeRequest -request $builtRequest -method 'PUT' -headers $destHeaders -body $body
    #header clean up
    $destHeaders.remove("Content-Type")
}

function postToDest ($endpoint, $parameters, $body){#submit new config to new environment
    if (!$parameters){
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $destDomain -environment $destDTEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Add Content-Type Header for API parsing
    $destHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    executeRequest -request $builtRequest -method 'POST' -headers $destHeaders -body $body
    #header clean up
    $destHeaders.remove("Content-Type")
}

function putToSource( $endpoint, $parameters, $body){#get Configruation from source environment
    if (!$parameters){
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceDTEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceDTEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Add Content-Type Header for API parsing
    $sourceHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    executeRequest -request $builtRequest -method 'PUT' -headers $sourceHeaders -body $body
    #header clean up
    $sourceHeaders.remove("Content-Type")
}

function getFromSource( $endpoint, $parameters){#get Configruation from source environment
    if (!$parameters){
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceDTEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceDTEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Execute request against API
    executeRequest -request $builtRequest -method 'GET' -headers $sourceHeaders 
}

function requestBuilder($endpoint, $parameters, $environment, $domain){#build string based on variables for script flexibility
    
    if($isManaged){
        if (!$parameters){
            'https://' + $domain + '/e/' + $environment + '/api/config/' + $apiversion + '/' + $endpoint
        }else {
            'https://' + $domain + '/e/' + $environment + '/api/config/' + $apiversion + '/' + $endpoint + "?" + $parameters
        }
    }else{
        if (!$parameters){
            'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + '/' + $endpoint
        }else {
            'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + $endpoint + "?" + $parameters
        }
    }
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