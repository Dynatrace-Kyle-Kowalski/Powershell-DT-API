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


function cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
    $dirtyResponse.psobject.properties.remove('metadata')
    $dirtyResponse.psobject.properties.remove('id')
    $dirtyResponse
}

<#Functions End#>

For ($i=0;$i -lt $updates.updates.Length;$i++){
    switch ($updates.updates[$i].config){
        "Tag"{
            $configEndpoint = '/autoTags'
        }
        default{
            Write-Host "This functionality has not been written yet see README for supported functions"
            Break
        }
    }

    if ($updates.updates[$i].newValue -ieq ""){
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

        }
        "AppPool"{

        }
        "WebApp"{

        }
        "DBName"{

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