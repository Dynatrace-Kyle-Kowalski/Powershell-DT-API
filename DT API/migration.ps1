#Path to project
$path = '.\DT API'
#DT Enironments to be used in migration
. $path'\core\dtCore.ps1'

#Try to read configs from json file
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $path'\Configs\environments.json')
    $migrations = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $path'\Configs\migration.json')
}catch{
    Write-Host "File Read Error" $_
    BREAK
}



<#FUNCTIONS LIST
migrateIDConfig ($configEndpoint, $configName, $sEnv, $dEnv){#Migration for rules that utilize a Dynatrace Hash ID
migrateMZConfig ($rules, $sEnv, $dEnv){#Migration for rules for management zones between environments
getEnvironment ($rule){#retrieve which dynatrace environment to be used
changeEnvironment ($mzConfig, $sEnv, $dEnv) {#Change environment tag   
cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
#>

function migrateMZConfig ($rules, $sEnv, $dEnv){#Migration for rules for management zones between environments
    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint '/managementZones'
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv  -endpoint ('/managementZones' + '/' + (getIdValue -apiResponse $sourceResponse -name ($rules.name + ' - ' + $rules.sEnv.ToUpper())))     
    }catch{
        Write-Host "Source Get Error - MZ"
        BREAK
    }

    try{
        #Get json element to search for config ID
        $destResponse = getFromDTEnv -dtEnv $dEnv -endpoint '/managementZones'
        #get ID from Destination system to update config of same name to Source
        $destID = getIdValue -apiResponse $destResponse -name ($rules.name + ' - ' + $rules.dEnv.ToUpper())
    }catch{
        Write-Host "Destination Get Error"
        BREAK
    }
    
    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse

    $cleanBody = changeEnvironment -mzConfig $cleanBody -sEnv $rules.sEnv -dEnv $rules.dEnv
    $cleanBody.name = ($rules.name + ' - ' + $rules.dEnv.ToUpper())
    try{
        if($migrations.backup -eq $true){#output json to backups file to save 
            try{
                backupConfig -path $path -body $cleanbody -config '/managementZones'
            }catch{
                Write-Host "config back up error"
            }
        }
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ('/managementZones' + '/' + $destID)
        }else{#create new configuration 
            postToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ('/managementZones')
        }

    }catch{
        Write-Host "Submission Error - MZ"
    }
    
}

function migrateIDConfig ($configEndpoint, $configName, $sEnv, $dEnv){#Migration for rules that utilize a Dynatrace Hash ID
    try{ 
        #Get json element to search for config ID
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint $configEndpoint
        #Get json element for config
        $sourceResponse = getFromDTEnv -dtEnv $sEnv -endpoint ($configEndpoint + '/' + (getIdValue -apiResponse $sourceResponse -name $configName))     
    }catch{
        Write-Host "Source Get Error" + $sourceResponse
        BREAK
    }

    try{
        #Get json element to search for config ID
        $destResponse = getFromDTEnv -dtEnv $dEnv  -endpoint $configEndpoint
        #get ID from Destination system to update config of same name to Source
        $destID = getIdValue -apiResponse $destResponse -name $configName
    }catch{
        Write-Host "Destination Get Error" + $destResponse
        BREAK
    }

    #cleanUpRequest
    $cleanBody = cleanMetaData -dirtyResponse $sourceResponse
    try{
        if($migrations.backup -eq $true){#output json to backups file to save 
            try{
                backupConfig -path $path -body $cleanbody -config $configEndpoint
            }catch{
                Write-Host "config back up error"
            }
        }
        #check for exisiting Config
        if ($destID){#put new json in for config
            putToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ($configEndpoint + '/' + $destID)
        }else{#create new configuration 
            postToDTEnv -dtEnv $dEnv -body $cleanBody -endpoint ($configEndpoint)
        }
    }catch{
        Write-Host "Submission Error"
    }
    
}

function getEnvironment ($rule){#retrieve which dynatrace environment to be used
    if($rule -ieq "Prod"){
        return $environments.prod
    }elseif ($rule -eq "DTTesting"){
        return $environments.testing
    }else{
        return $environments.nonProd
    }
}

function changeEnvironment ($mzConfig, $sEnv, $dEnv) {#Change environment tag 
    #I'm sure there is a better way to do this but I don't know PS well enough
    For($i=0;$i -lt $mzConfig.rules.Length; $i++){
        For($j=0;$j -lt $mzConfig.rules[$i].conditions.Length;$j++){
            if($mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value -ieq $sEnv){
                $mzConfig.rules[$i].conditions[$j].comparisonInfo.value.value = $dEnv
            }
        }
    }
    $mzConfig
}
function cleanMetaData ($dirtyResponse){#clean cluster meta data and ID
    $dirtyResponse.psobject.properties.remove('metadata')
    $dirtyResponse.psobject.properties.remove('id')
    $dirtyResponse
}

<#Functions End#>

For ($i=0;$i -lt $migrations.rules.Length;$i++){

    $sEnv = getEnvironment -rule $migrations.rules[$i].sEnv
    $dEnv = getEnvironment -rule $migrations.rules[$i].dEnv

    if($migrations.rules[$i].endpoint -eq "/managementZones"){
        migrateMZConfig -rules $migrations.rules[$i] -sEnv $sEnv -dEnv $dEnv 
    }else{
        migrateIDConfig -configEndpoint $migrations.rules[$i].endpoint -configName $migrations.rules[$i].name -sEnv $sEnv -dEnv $dEnv 
    }
}
