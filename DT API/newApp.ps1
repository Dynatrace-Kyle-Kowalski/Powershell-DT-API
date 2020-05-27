#Path to project
$path = '.\DT API'
#DT Enironments to be used in migration
. $path'\core\dtCore.ps1'

#Try to read configs from json file
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $path'\Configs\environments.json')
    $newApp = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $path'\Configs\newApp.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
<#API FRAME WORK SET UP END#>

#Set environment to be used
if($newApp.environment -ieq "Prod"){
    $sEnv = $environments.prod
}elseif ($newApp.environment -eq "DTTesting"){
    $sEnv = $environments.testing
}else{
    $sEnv = $environments.nonProd
}



<#FUNCTIONS LIST
addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue)
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

function addBasicRule ($sJson, $entity, $condtionKey, $conditionValue, $optionalValue){#Format rules string to update an exisiting rule configuration
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

#loop through new App File
For ($i=0;$i -lt $newApp.tags.values.Length;$i++){
    $configEndpoint = '/autoTags'

    try{ 
        #Get json element to search for config ID
        $sourceID = getIdValue -apiResponse (getFromDTEnv -dtEnv $sEnv -endpoint $configEndpoint) -name $newApp.tags.values[$i].Name
        $name = $newApp.tags.values[$i].Name
        if($null -eq $sourceID){#if tag does not exist create it
            #format new tag Json
            $newTag =  ConvertFrom-Json -InputObject @"
            {
                "name" : "$name",
                "rules" : []
            }
"@
            #create new tag value
            $sourceID = postToDTEnv -dtEnv $sEnv -body $newTag -endpoint ($configEndpoint)
            #get new id
            $sourceID = $sourceID.id 
        }
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint ($configEndpoint + '/' + $sourceID)     
    }catch{
        Write-Host "Source Get Error -"  $_
        BREAK
    }

    #loop though all conditions
    For($j=0;$j -lt $newApp.tags.conditions.Length;$j++){
        $key = $null 
        switch ($newApp.tags.conditions[$j].key){
            "HostGroup"{
                $key = createKey -type $newApp.tags.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "PROCESS_GROUP" -condtionKey $key -conditionValue $newApp.tags.conditions[$j].value -optionalValue $newApp.tags.values[$i].Value
                $newRule.rules[($newRule.rules.Length-1)].propagationTypes += "PROCESS_GROUP_TO_SERVICE"
                $newRule.rules[($newRule.rules.Length-1)].propagationTypes += "PROCESS_GROUP_TO_HOST"
            }
            "AppPool"{
                $key = createKey -type $newApp.tags.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "PROCESS_GROUP" -condtionKey $key  -conditionValue $newApp.tags.conditions[$j].value -optionalValue $newApp.tags.values[$i].Value
                $newRule.rules[($newRule.rules.Length-1)].propagationTypes += "PROCESS_GROUP_TO_SERVICE"
            }
            "WebApp"{
                $key = createKey -type $newApp.tags.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "APPLICATION" -condtionKey $key  -conditionValue $newApp.tags.conditions[$j].value -optionalValue $newApp.tags.values[$i].Value
            }
            "DBName"{
                $key = createKey -type $newApp.tags.conditions[$j].key
                #Set properties for adding rule object to config
                $newRule = addBasicRule -sJson $sourceResponse -entity "SERVICE" -condtionKey $key  -conditionValue $newApp.tags.conditions[$j].value -optionalValue $newApp.tags.values[$i].Value
            }
            default{
                Write-Host "Unsupported Rule"
                break
            }
        }
        #submit config back into system
        try{
            putToDTEnv -dtEnv $sEnv -body $newRule -endpoint ($configEndpoint + '/' + $sourceID)
        }catch{
            Write-Host "Submission Error - " $newApp.tags.values[$i].Name ":" $newApp.tags.conditions[$j].key
            Write-Host $_
        }
    }

}