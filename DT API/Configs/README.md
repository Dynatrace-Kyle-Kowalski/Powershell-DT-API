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
  
*Migration Permissions*
```
Read Configuration 
Write Configuration
```
>***isDTManaged***

Flag used to determine if environments are within a managed environment



## migration.json

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

>***tags***

list of tags to add to environment 

>***conditions***

set of conditions needed for tags above. Current key values supported {HostGroup,DBName, WebApp, AppPool}