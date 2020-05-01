#Script to use to onboard a new application in Dynatrace SaaS

#Requried API inputs
$environment = 'vkw74953'
$domain = 'sprint.dynatracelabs.com'
$token = 'XvhWZ00LRU27DkUmsyVBq'

#"Dynamic" Parameters
$apiversion = 'v1'

<# Script Execution Start #>


#Create Header Object for request to use certian objects may add to this header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$headers.Add("Authorization", "Api-Token "+ $token)


#build Auto Tags request
$uri = '/autoTags/'
$builtRequest = requestBuilder -endpoint $uri
#Execute request against API
$response = executeRequest -request $builtRequest -method 'GET' -headers $headers 

#Build AutoTag/ID request for configurations
$entityID = getIdValue -apiResponse $response -name "service"
$uri = '/autoTags/'+ $entityID
$builtRequest = requestBuilder -endpoint $uri
#Execute request against API
$response = executeRequest -request $builtRequest -method 'GET' -headers $headers 

#Set properties for adding rule object to config
$newRules = addNewRule -entity "PROCESS_GROUP" -condtionKey "HOST_GROUP_NAME"  -conditionValue "FunctionTest"
#Add new rule object to list of rules
$newRules = $response.rules += $newRules



<# Script Execution End #>

$newRules | ConvertTo-Json -Depth 24



<#FUNCTIONS LIST
addNewRule ($entity, $condtionKey, $conditionValue)
executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
#>
function addNewRule ($entity, $condtionKey, $conditionValue)
{#Format rules string to update an exisiting rule configuration
    $rulesJson = @"
    {
        "type":  "$entity",
        "enabled":  true,
        "valueFormat":  null,
        "propagationTypes":  [
                             ],
        "conditions":  [
                           {
                               "key":  "{attribute=$condtionKey}",
                               "comparisonInfo":  "{type=STRING; operator=CONTAINS; value=$conditionValue; negate=False; caseSensitive=False}"
                           }
                       ]
    }
"@

    ConvertFrom-Json -InputObject $rulesJson
}


function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
    #Write-Host $request
    Invoke-RestMethod $request -Method $method -Headers $headers -Body $body   
} 

function requestBuilder($endpoint, $parameters)
{#build string based on variables for script flexibility
    if (!$parameters)
    {
        'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + $endpoint
    }else {
        'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + $endpoint + "?" + $parameters
    }
    
}

function getIdValue($apiResponse ,$name)
{#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $return = $apiResponse.values | Where-Object {$_.name -eq $name}
    $return.id
}