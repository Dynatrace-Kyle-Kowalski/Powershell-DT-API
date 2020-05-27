# Powershell-DT-API
Powershell scripts to help with common Dynatrace API Tasks. Each script takes the enviornments.json file to use to generate tokens and help centralize configs. In addition to the environments.json file each script has a config file it takes as inputs.


###Installation
Please be sure to Unblock the files following
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-7

## Current Functions
**migration.ps1**
Migrate ID based configs from 1 environment to another 

**newApp.ps1**
Create Tag values for onboarding a new application

  Currently Supported values
    (DB Name, Web App Name, IIS App Pool Name, Host Group Name)

**update.ps1**
Update a configuration from an old value to new

  Currently tested to update auto tag values used in New App Script
