# Powershell-DT-API
Powershell scripts to help with common Dynatrace API Tasks. Each script takes the enviornments.json file to use to generate tokens and help centralize configs. In addition to the environments.json file each script has a config file it takes as inputs.

## Current Functions
**migration.ps1**
Migrate ID based configs from 1 environment to another 
### environment.json
Enter API information in environments.json to designate environmental propeties for API useage

>***Environment***: 
  
 Managed Location : https://mangedDTDomain.com/e/ **environmentID**
   
  Saas Location:     https://**environmentID**.live.dynatrace.com
>***Domain***:

 Managed Location : https://**mangedDTDomain.com**/e/environmentID

  Saas Location:     https://environmentID. **live.dynatrace.com**
>***APIToken***:
  
*Migration Permissions*
```
Read Configuration 
Write Configuration
```
>***isDTManaged***

Flag used to determine if environments are within a managed environment



### migration.json

>***Rules***

Iterative list of all changes to be made

>***Endpoint***

What config to migrate over. NOTE this is the URI of the config api without the trailing slash

>***Name***

Name of the configuration to move over

>***sEnv***

Source environment to be used. If this value is prod it will go to the prod environment listed in the environments.json otherwise it will default to non-prod

>***dEnv***

Destination environment to be used. If this value is prod it will go to the prod environment listed in the environments.json otherwise it will default to non-prod