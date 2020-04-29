#Script to use to onboard a new application in Dynatrace SaaS

#Requried API inputs
$environment = 'vkw74953'
$domain = 'sprint.dynatracelabs.com'
$token = 'XvhWZ00LRU27DkUmsyVBq'

#"Dynamic" Parameters
$apiversion = 'v1'


#Create Header Object for request to use certian objects may add to this header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
#Add Auth Header for API to use
$headers.Add("Authorization", "Api-Token "+ $token)


#build Auto Tags request
$temp | requestBuilder -endpoint '/autoTags' 
#Execute request against API
$response | executeRequest -request $temp -method 'GET' -headers $headers 

$response | ConvertTo-Json

function executeRequest ( $request , $method, $headers, $body )
{ #Execute api requests
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