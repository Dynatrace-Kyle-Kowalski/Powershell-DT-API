<# Script for core function used in other scripts

Functions List
    executeRequest ( $request , $method, $headers, $body ){ #Execute api requests
    postToDtEnv ($dtEnv, $endpoint, $parameters, $body){#submit new config to Dynatrace environment
    putToDTEnv($dtEnv, $endpoint, $parameters, $body){#update Configruation from Dynatrace environment
    getFromDTEnv($dtEnv, $endpoint, $parameters){#get Configruation from Dynatrace environment
    requestBuilder($endpoint, $parameters, $environment){#build string based on variables for script flexibility
    getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
    backupConfig ($path ,$body ,$config){#output json object to backups directory
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


function postToDtEnv ($dtEnv, $endpoint, $parameters, $body, $api){#submit new config to Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder  -environment $dtEnv -endpoint $endpoint -api $api
    }else{
        $builtRequest = requestBuilder  -environment $dtEnv -endpoint $endpoint -parameters $parameters -api $api
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

function putToDTEnv($dtEnv, $endpoint, $parameters, $body, $api){#update Configruation from Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -api $api
    }else{
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -parameters $parameters -api $api
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

function getFromDTEnv($dtEnv, $endpoint, $parameters, $api){#get Configruation from Dynatrace environment
    if (!$parameters){
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -api $api
    }else{
        $builtRequest = requestBuilder -environment $dtEnv -endpoint $endpoint -parameters $parameters -api $api
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

function requestBuilder($endpoint, $parameters, $environment, $api){#build string based on variables for script flexibility
    #TODO - Figure out how to make this more flexible without destroying config workflows
    if ($api -eq 'enviornment') {
        if($environment.isDTManaged -ieq $true){
            if (!$parameters){
                'https://' + $environment.Domain + '/e/' + $environment.Environment + '/api/' + 'v2' + $endpoint
            }else {
                'https://' + $environment.Domain + '/e/' + $environment.Environment + '/api/' + 'v2' + $endpoint + "?" + $parameters
            }
        }else{
            if (!$parameters){
                'https://' + $environment.Environment + '.' + $environment.Domain + '/api/' + 'v2'  + $endpoint
            }else {
                'https://' + $environment.Environment + '.' + $environment.Domain + '/api/' + 'v2' + $endpoint + "?" + $parameters
            }
        }
    }else{
        if($environment.isDTManaged -ieq $true){
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

}

function getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $idReturn = $apiResponse.values | Where-Object {$_.name -eq $name}
    $idReturn.id
}


function backupConfig ($path ,$body ,$config){#output json object to backups directory
    #remove api slash
    $config = $config.Trim("/")
    #get date for rolling files
    $date = Get-Date -Format "yyyyMMddZHHmm"
    #get config name from json
    $name = $body.name
    #convert body to json
    $body = ConvertTo-Json -depth 24 -InputObject $body
    
    if (-not (Test-Path -Path "$path\backups")){#check if backups directory exisits if not create
        New-Item -Path "$path" -Name 'backups' -ItemType "Directory"
    }
    if (-not (Test-Path -Path "$path\backups\$date")){#check if date directory exisits if not create
        New-Item -Path "$path\backups\" -Name $date -ItemType "Directory"
    }
    if (-not (Test-Path -Path "$path\backups\$date\$config")){#check if configuration directory exisits if not create
        New-Item -Path "$path\backups\$date" -Name $config -ItemType "Directory"
    }
    
    if (-not (Test-Path -Path "$path\backups\$date\$config\$name.json.bak" -PathType Leaf)){
        New-Item -Path "$path\backups\$date\$config" -Name "$name.json.bak" -ItemType "File" -Value $body
    }else{
        $temp = Get-Date -Format "HHmmssffff"
        New-Item -Path "$path\backups\$date\$config" -Name "$name-$temp.json.bak" -ItemType "File" -Value $body
    }
}