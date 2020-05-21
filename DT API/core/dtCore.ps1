<# Script for core function used in other scripts

Functions List
    executeRequest ( $request , $method, $headers, $body ){ #Execute api requests
    postToDtEnv ($dtEnv, $endpoint, $parameters, $body){#submit new config to Dynatrace environment
    putToDTEnv($dtEnv, $endpoint, $parameters, $body){#update Configruation from Dynatrace environment
    getFromDTEnv($dtEnv, $endpoint, $parameters){#get Configruation from Dynatrace environment
    requestBuilder($endpoint, $parameters, $environment){#build string based on variables for script flexibility
    getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
#>

#Set API version to be used
$apiversion = 'v1'


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

function putToDTEnv($dtEnv, $endpoint, $parameters, $body){#update Configruation from Dynatrace environment
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
