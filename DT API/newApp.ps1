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
$response = addNewRule -sJson $response -entity "PROCESS_GROUP" -condtionKey "HOST_GROUP_NAME"  -conditionValue "FunctionTest"



<# Script Execution End #>

$response | ConvertTo-Json -Depth 24



<#FUNCTIONS LIST
addNewRule ($sJson, $entity, $condtionKey, $conditionValue)
executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
#>
function addNewRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)
{#Format rules string to update an exisiting rule configuration
    if (!$optionalValue)
    {
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
                                "key":  "{attribute=$condtionKey}",
                                "comparisonInfo":  "{type=STRING; operator=CONTAINS; value=$conditionValue; negate=False; caseSensitive=False}"
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
                                "key":  "{attribute=$condtionKey}",
                                "comparisonInfo":  "{type=STRING; operator=CONTAINS; value=$conditionValue; negate=False; caseSensitive=False}"
                            }
                        ]
        }
"@
    }
    #Convert jSon to Powershell object for adding new rule
    $newRules = ConvertFrom-Json -InputObject $rulesJson -Depth 16
    #Add new rule object to list of rules
    $newRules = $sJson.rules += $newRules
}

function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
    #Write-Host $request
    if($body){ #check for body which should be a powershell object
        $body = ConvertTo-Json -depth 24 -InputObject $body
    }
    Invoke-RestMethod $request -Method $method -Headers $headers -Body $body   
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

function getIdValue($apiResponse ,$name){#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $idReturn = $apiResponse.values | Where-Object {$_.name -eq $name}
    $idReturn.id
}