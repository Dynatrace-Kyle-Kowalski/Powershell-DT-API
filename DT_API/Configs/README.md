Look in templates directory for examples of these files

## environment.json
Enter API information in environments.json to designate environmental propeties for API useage

>***Environment***: 
  
 Managed Location : https://mangedDTDomain.com/e/ **environmentID**
   
  Saas Location:     https://**environmentID**.live.dynatrace.com
>***Domain***:

 Managed Location : https://**mangedDTDomain.com**/e/environmentID

  Saas Location:     https://environmentID. **live.dynatrace.com**
>***APIToken***:
  
*Token Permissions Required*
```
Read Configuration 
Write Configuration
```

>***isDTManaged***

Flag used to determine if environments are within a managed environment


## migration.json
>***Backup***

Boolean value indicating if config should also create a back up

>***Rules***

Iterative list of all changes to be made

>***Endpoint***

What config to migrate over

>***Name***

Name of the configuration to move over

>***sEnv***

Source environment to be used. If this value is prod it will go to the prod environment listed in the environments.json otherwise it will default to non-prod

>***dEnv***

Destination environment to be used. If this value is prod it will go to the prod environment listed in the environments.json otherwise it will default to non-prod


## newApp.json
>***environment***

select which enviornment this script should run against

>***tags***

Tags object consisting of values and conditions

>***values***

List out the different tags and optional values for the conditions to apply to

>***conditions***

set of conditions needed for tags above. Current key values supported {HostGroup,DBName, WebApp, AppPool}


## update.json
>***environment***

select which enviornment this script should run against

>***backup***

Boolean value indicating if config should also create a back up of orginial config

>***updates***

List of update objects to iterate through each object has the following values

>***config***

Config endpoint needed to be updated

>***name***

Name of the item within the endpoint listed

>***item***

Which piece of the config to update. Main values are derived from the newApp process
{Value,HostGroup,DBName, WebApp, AppPool}

>***oldValue***

Name of the old value to update CASE SENSITIVE

>***newValue***

Name of the new value to update CASE SENSITIVE