. '.\DT API\core\dtCore.ps1'

#Try to read configs from json file
#\Documents\Code\Powershell
try{
    $environments = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\environments.json')
    $update = ConvertFrom-Json -InputObject (Get-Content -Raw -Path '.\DT API\Configs\update.json')
}catch{
    Write-Host "File Read Error"
    BREAK
}
<#API FRAME WORK SET UP END#>

#Set environment to be used
$sEnv = $environments.testing

