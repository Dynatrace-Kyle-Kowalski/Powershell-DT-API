# Powershell-DT-API
Powershell scripts to help with common Dynatrace API Tasks

## Current Functions
**migration.ps1**
Migrate ID based configs from 1 environment to another 
### Usage
Enter API information in environments json to designate which environments to migrate to

>***Environment***: 
 >   
 Managed Location : https://mangedDTDomain.com/e/**environmentID**
  >  
  Saas Location:     https://**environmentID**.live.dynatrace.com
>***Domain***:

 Managed Location : https://**mangedDTDomain.com**/e/environmentID

  Saas Location:     https://environmentID.**live.dynatrace.com**
>***APIToken***:
 
*Source Permissions*
   
 ```
 Read Configuration 
 ```
 
*Destination Permissions*
```
Read Configuration 
Write Configuration
```

>***isDTManaged***

Flag used to determine if environments are within a managed environment
