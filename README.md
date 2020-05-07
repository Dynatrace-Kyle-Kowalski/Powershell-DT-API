# Powershell-DT-API
Powershell scripts to help with common Dynatrace API Tasks

##Current Functions
**migration.ps1**
Migrate ID based configs from 1 environment to another 
###Usage
Enter API information in environments json to designate which environments to migrate to
***environment***: 
    Managed Location : https://mangedDTDomain.com/e/**environmentID**
    Saas Location:     https://**environmentID**.live.dynatrace.com
***domain***:
    Managed Location : https://**mangedDTDomain.com**/e/environmentID
    Saas Location:     https://environmentID.**live.dynatrace.com**
***token***:
    *Source*
    Read Configuration 
    *Destination*
    Read Configuration
    Write Configuration