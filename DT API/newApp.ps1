#DT Enironments to be used in migration

<#API FRAME WORK SET UP START#>
#Set API version to be used
$apiversion = 'v1'

#Try to read configs from json file
#\Documents\Code\Powershell
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\environments.json')
    $newApp = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\newApp.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
<#API FRAME WORK SET UP END#>

<#FUNCTIONS LIST
addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)


executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
getFromSource( $endpoint, $parameters)
putToSource( $endpoint, $parameters, $body)
#>


function createKey ($type){#generate key value for the different rules
    $return = ""
    switch ($type){
        "HostGroup"{
            $return = '{"attribute": "HOST_GROUP_NAME"}'
        }
        "AppPool"{
            $return = '{"attribute": "PROCESS_GROUP_PREDEFINED_METADATA", "dynamicKey": "IIS_APP_POOL","type": "PROCESS_PREDEFINED_METADATA_KEY"}'
        }
        "WebApp"{
            $return ='{"attribute": "WEB_APPLICATION_NAME"}'
        }
        "DBName"{
            $return = '{"attribute": "SERVICE_DATABASE_NAME"}'
        }
        default{
            Write-Host "Unsupported Rule"
        }
    }
    $return 
}

function addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)
{#Format rules string to update an exisiting rule configuration
    if ($null -ne $optionalValue){
        #New Rules Object with Optional Tag name
        $rulesJson = @"
        {
            "type":  "$entity",
            "enabled":  true,
            "valueFormat":  "$optionalValue",
            "propagationTypes":  [
                                ],
            "conditions":  [
                            {
                                "key":  $condtionKey,
                                "comparisonInfo":  {
                                    "type": "STRING",
                                    "operator": "CONTAINS", 
                                    "value": "$conditionValue", 
                                    "negate": false,
                                    "caseSensitive": false
                                }
                            }
                        ]
        }
"@
    }else{
        #New Rules Object without optional value
        $rulesJson = @"
        {
            "type":  "$entity",
            "enabled":  true,
            "valueFormat":  null,
            "propagationTypes":  [
                                ],
            "conditions":  [
                            {
                                "key":  $condtionKey,
                                "comparisonInfo":  {
                                    "type": "STRING",
                                    "operator": "CONTAINS", 
                                    "value": "$conditionValue", 
                                    "negate": false,
                                    "caseSensitive": false
                                }
                            }
                        ]
        }
"@
    }
    #Convert jSon to Powershell object for adding new rule
    $newRules = ConvertFrom-Json -InputObject $rulesJson 
    #Add new rule object to list of rules
    $sJson.rules += $newRules
    return $sJson
}

function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
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

function getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $idReturn = $apiResponse.values | Where-Object {$_.name -eq $name}
    $idReturn.id
}



#loop through new App File
For ($i=0;$i -lt $newApp.tags.Length;$i++){
    $configEndpoint = '/autoTags'
    $sEnv = $environments.testing

    try{ 
        #Get json element to search for config ID
        $sourceID = getIdValue -apiResponse (getFromDTEnv -dtEnv $sEnv -endpoint $configEndpoint) -name $newApp.tags[$i].Name
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint ($configEndpoint + '/' + $sourceID)     
    }catch{
        Write-Host "Source Get Error" + $sourceResponse
        BREAK
    }

    #loop though all conditions
    For($j=0;$j -lt $newApp.conditions.Length;$j++){
        $key = $null 
        switch ($newApp.conditions[$j].key){
            "HostGroup"{
                $key = createKey -type $newApp.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "PROCESS_GROUP" -condtionKey $key -conditionValue $newApp.conditions[$j].value -optionalValue $newApp.tags[$i].Value
            }
            "AppPool"{
                $key = createKey -type $newApp.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "PROCESS_GROUP" -condtionKey $key  -conditionValue $newApp.conditions[$j].value -optionalValue $newApp.tags[$i].Value
            }
            "WebApp"{
                $key = createKey -type $newApp.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "APPLICATION" -condtionKey $key  -conditionValue $newApp.conditions[$j].value -optionalValue $newApp.tags[$i].Value
            }
            "DBName"{
                $key = createKey -type $newApp.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "SERVICE" -condtionKey $key  -conditionValue $newApp.conditions[$j].value -optionalValue $newApp.tags[$i].Value
            }
            default{
                Write-Host "Unsupported Rule"
                break;
            }
        }
        #submit config back into system
        try{
           # if ($sourceID){#check if ID exisits if not create new rule
                putToDTEnv -dtEnv $sEnv -body $newRule -endpoint ($configEndpoint + '/' + $sourceID)
         <#    }else{#create new configuration 
                postToDTEnv -dtEnv $sEnv -body $sourceResponse -endpoint ($configEndpoint)
            } #>
        }catch{
            Write-Host "Submission Error - " $newApp.tags[$i].Name ":" $newApp.conditions[$j].key
            Write-Host $_
        }
    }

}