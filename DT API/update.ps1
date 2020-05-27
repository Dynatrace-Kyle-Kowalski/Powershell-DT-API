. '.\DT API\core\dtCore.ps1'

#Try to read configs from json file
#\Documents\Code\Powershell
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\environments.json')
    $updates = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\update.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
<#API FRAME WORK SET UP END#>

#Set environment to be used
$sEnv = $environments.testing

<# Functions List
function changeValue ($json, $old, $new) {#Change optional tag value
function changeHostGroup ($json, $old, $new) {#Change host group value
function changeDBName ($json, $old, $new) {#Change DBname
function changeWebApp ($json, $old, $new) {#Change WebApp name
function changeAppPool ($json, $old, $new) {#Change AppPool name
function cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
#>

function changeValue ($json, $old, $new) {#Change optional tag value
    #update all optional values present in Json tha match the old value
    For($i=0;$i -lt $json.rules.Length; $i++){
        if($json.rules[$i].valueFormat -ieq $old){
            $json.rules[$i].valueFormat = $new
        }
    }
    $json
}
function changeHostGroup ($json, $old, $new) {#Change host group value
    #update all hostgroup values present in Json tha match the old value
    For($i=0;$i -lt $json.rules.Length; $i++){
        if($json.rules[$i].conditions.comparisonInfo.value -ieq $old -And $json.rules[$i].conditions.key.attribute -eq "HOST_GROUP_NAME"){
            $json.rules[$i].conditions.comparisonInfo.value = $new
        }
    }
    $json
}
function changeDBName ($json, $old, $new) {#Change DBname
    #update all matching DBName values present in Json tha match the old value
    For($i=0;$i -lt $json.rules.Length; $i++){
        if($json.rules[$i].conditions.comparisonInfo.value -ieq $old -And $json.rules[$i].conditions.key.attribute -eq "SERVICE_DATABASE_NAME"){
            $json.rules[$i].conditions.comparisonInfo.value = $new
        }
    }
    $json
}
function changeWebApp ($json, $old, $new) {#Change WebApp name
    #update all matching WebApp values present in Json tha match the old value
    For($i=0;$i -lt $json.rules.Length; $i++){
        if($json.rules[$i].conditions.comparisonInfo.value -ieq $old -And $json.rules[$i].conditions.key.attribute -eq "WEB_APPLICATION_NAME"){
            $json.rules[$i].conditions.comparisonInfo.value = $new
        }
    }
    $json
}
function changeAppPool ($json, $old, $new) {#Change AppPool name
    #update all matching AppPool values present in Json tha match the old value
    For($i=0;$i -lt $json.rules.Length; $i++){
        if($json.rules[$i].conditions.comparisonInfo.value -ieq $old -And $json.rules[$i].conditions.key.dynamicKey -eq "IIS_APP_POOL"){
            $json.rules[$i].conditions.comparisonInfo.value = $new
        }
    }
    $json
}
function cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
    $dirtyResponse.psobject.properties.remove('metadata')
    $dirtyResponse.psobject.properties.remove('id')
    $dirtyResponse
}

<#Functions End#>

For ($i=0;$i -lt $updates.updates.Length;$i++){#loop to update elements defined in Json
    switch ($updates.updates[$i].config){
        "/autoTags"{
            $configEndpoint = '/autoTags'
        }
        default{
            Write-Host "This functionality has not been written yet see README for supported functions"
            Break
        }
    }

    if ($updates.updates[$i].newValue -ieq ""){ #check that new value exisits
        Write-Host "Update object " $i " does not have a valid value"
        Break
    }

    try{#Get json element to search for config ID
        $sourceID = getIdValue -apiResponse (getFromDTEnv -dtEnv $sEnv -endpoint $configEndpoint) -name $updates.updates[$i].name
        if($null -eq $sourceID){
            Write-Host "ERROR - Name "$updates.updates[$i].name " does not exisit"
            break
        }
        #Get json element for config
        $dtResponse = getFromDTEnv -dtEnv $sEnv -endpoint ($configEndpoint + '/' + $sourceID) 
    }catch{
        Write-Host "Source Get Error -"  $_
        BREAK
    }

    switch ($updates.updates[$i].item) {
        "Value" {
            $newRule = changeValue -json $dtResponse -old $updates.updates[$i].oldValue -new $updates.updates[$i].newValue
        }
        "HostGroup"{
            $newRule = changeHostGroup -json $dtResponse -old $updates.updates[$i].oldValue -new $updates.updates[$i].newValue
        }
        "AppPool"{
            $newRule = changeAppPool -json $dtResponse -old $updates.updates[$i].oldValue -new $updates.updates[$i].newValue
        }
        "WebApp"{
            $newRule = changeWebApp -json $dtResponse -old $updates.updates[$i].oldValue -new $updates.updates[$i].newValue
        }
        "DBName"{
            $newRule = changeDBName -json $dtResponse -old $updates.updates[$i].oldValue -new $updates.updates[$i].newValue
        }
        Default {
            Write-Host "This functionality has not been written yet see README for supported functions"
            Break
        }
    }

    try{#sumbit changes back into DT system
        putToDTEnv -dtEnv $sEnv -body (cleanMetaData -dirtyResponse $newRule) -endpoint ($configEndpoint + '/' + $sourceID)
    }catch{
        Write-Host "Submission Error - " $newApp.tags[$i].Name ":" $newApp.conditions[$j].key
        Write-Host $_
    }
}


