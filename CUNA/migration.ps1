$tagName = ''

<#API FRAME WORK SET UP START#>
#Requried API inputs
$isManaged = $False

$sourceEnvironment = 'goy71950'
$sourceDomain = 'live.dynatrace.com'
$sourceToken = '<Token Here>'

$destEnvironment = 'wzj14229'
$destDomain = 'live.dynatrace.com'
$destToken = '<Token Here>'

#"Dynamic" Parameters
$apiversion = 'v1'

#Create Header Object for request to use certian objects may add to this header
$sourceHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$sourceHeaders.Add("Authorization", "Api-Token "+ $sourceToken)

#Create Header Object for request to use certian objects may add to this header
$destHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$destHeaders.Add("Authorization", "Api-Token "+ $destToken)
<#API FRAME WORK SET UP END#>

migrateRulesConfig -configEndpoint 'autoTags' -configName $tagName 

<#FUNCTIONS LIST
executeRequest ( $request , $method, $headers, $body )
requestBuilder($endpoint, $parameters)
getIdValue($apiResponse ,$name)
getFromSource( $endpoint, $parameters)
#>

function migrateRulesConfig ($configEndpoint, $configName)
{
    #Get json element to search for config ID
    $sourceResponse = getFromSource -endpoint $configEndpoint
    #Get json element for config
    $sourceResponse = getFromSource -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))

    #Get json element to search for config ID
    $destResponse = getFromDest -endpoint $configEndpoint
    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse
    #put new json element for config
    putToDest -body $cleanBody -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $destResponse -name $configName))
}


function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
    #Write-Host $request
    if($body)
    {
        $body = ConvertTo-Json -depth 24 -InputObject $body
    }
    Invoke-RestMethod $request -Method $method -Headers $headers -Body $body   
} 

function getFromDest ($endpoint, $parameters)
{#submit config to new environment
    if (!$parameters)
    {
        $builtRequest = requestBuilder -domain $destDomain -environment $destEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $destDomain -environment $destEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Execute request against API
    executeRequest -request $builtRequest -method 'GET' -headers $destHeaders 
}

function putToDest ($endpoint, $parameters, $body)
{#submit config to new environment
    if (!$parameters)
    {
        $builtRequest = requestBuilder -domain $destDomain -environment $destEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $destDomain -environment $destEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Add Content-Type Header for API parsing
    $destHeaders.Add("Content-Type", "application/json")
    #Execute request against API
    executeRequest -request $builtRequest -method 'PUT' -headers $destHeaders -body $body
    #header clean up
    $destHeaders.remove("Content-Type", "application/json")
}

function putToSource( $endpoint, $parameters)
{#get Configruation from source environment
    if (!$parameters)
    {
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Execute request against API
    executeRequest -request $builtRequest -method 'PUT' -headers $sourceHeaders 
}

function getFromSource( $endpoint, $parameters)
{#get Configruation from source environment
    if (!$parameters)
    {
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceEnvironment -endpoint $endpoint 
    }else{
        $builtRequest = requestBuilder -domain $sourceDomain -environment $sourceEnvironment -endpoint $endpoint -parameters $parameters
    }
    #Execute request against API
    executeRequest -request $builtRequest -method 'GET' -headers $sourceHeaders 
}

function requestBuilder($endpoint, $parameters, $environment, $domain)
{#build string based on variables for script flexibility
    
    if(!$isManaged)
    {
        if (!$parameters)
        {
            'https://' + $domain + '/e/' + $environment + '/api/config/' + $apiversion + '/' + $endpoint
        }else {
            'https://' + $domain + '/e/' + $environment + '/api/config/' + $apiversion + '/' + $endpoint + "?" + $parameters
        }
    }else{
        if (!$parameters)
        {
            'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + '/' + $endpoint
        }else {
            'https://' + $environment + '.' + $domain + '/api/config/' + $apiversion + $endpoint + "?" + $parameters
        }
    }
}

function cleanMetaData ($dirtyResponse)
{#clean cluster meta data and ID
    $dirtyResponse.psobject.properties.remove('metadata')
    $dirtyResponse.psobject.properties.remove('id')
    $dirtyResponse
}

function getIdValue($apiResponse ,$name)
{#Query the ID list to find the id needed
    #Write-Host $apiResponse
    $idReturn = $apiResponse.values | Where-Object {$_.name -eq $name}
    $idReturn.id
}