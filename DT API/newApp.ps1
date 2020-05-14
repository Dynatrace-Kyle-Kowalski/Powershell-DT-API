#Script to use to onboard a new application in Dynatrace SaaS

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


#Create Header Object for request to use certian objects may add to this header
$sourceHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$sourceHeaders.Add("Authorization", "Api-Token "+ $sourceToken)

<#API FRAME WORK SET UP END#>

$configEndpoint = 'autoTags'

#Get json element to search for config ID
$sourceResponse = getFromSource -endpoint $configEndpoint
#Get json element for config
$sourceResponse = getFromSource -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))      

#Set properties for adding rule object to config
$sourceResponse = addBasicRule -sJson $sourceResponse -entity "PROCESS_GROUP" -condtionKey "HOST_GROUP_NAME"  -conditionValue "FunctionTest"



<# Script Execution End #>




<#FUNCTIONS LIST
addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)


executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
getFromSource( $endpoint, $parameters)
putToSource( $endpoint, $parameters, $body)


#>
function addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)
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