---
layout: post
title: Customize Sitecore Azure toolkit deployment
tags: sitecore deployment
categories: azure
date: 2016-12-10
---

* TOC
{:toc}

Get familiar with [packaging approach for Sitecore on Azure][sat-packaging] (SoA) to understand the basics of packaging SoA solution.
Also check out [Getting started with Sitecore Azure Toolkit][sat-get-started] to understand configuration peices of packaing process.  
>[Sitecore Azure Toolkit](https://dev.sitecore.net/Downloads/Sitecore_Azure_Toolkit/1x/Sitecore_Azure_Toolkit_100.aspx) may also be referred to as Sitecore Azure SDK or Provisioning SDK.  

This article explains what you need to do to create a custom configuration of SoA Web Deployment Package (WDP). Described configuration below is catered to example ARM templates 
[AM0](https://github.com/ivansharamok/Sitecore-Azure-Quickstart-Templates/tree/master/Sitecore%208.2.1/am0), 
[AM](https://github.com/ivansharamok/Sitecore-Azure-Quickstart-Templates/tree/master/Sitecore%208.2.1/am), 
[AMS](https://github.com/ivansharamok/Sitecore-Azure-Quickstart-Templates/tree/master/Sitecore%208.2.1/ams).  
Unlike [XM](https://github.com/ivansharamok/Sitecore-Azure-Quickstart-Templates/tree/master/Sitecore%208.2.1/xm) deployment type, AM type is created to deploy Sitecore app and connect it to already existing resources.

## Expanded view of SAT resources

This is to add to what's mentioned in [offical doc article][sat-get-started] and SAT README file.

### Cargo payloads (SCCPL) packages

SCCPL packages located at /cargopayloads folder in Sitecore Azure Toolkit (SAT) distributive. They hold configurations that can be applied to WDP during the packaging time. There are common SCCPL as well as role specific ones. 
For example, `Sitecore.Cloud.Security.sccpl` contains SQL scripts that get executed to configure Sitecore databases (i.e. set up database users, configure Sitecore admin user password) during deployment. 
>For more details on how to create custom SCCPL packages check out [Bas Lijten's blog post](http://blog.baslijten.com/sitecore-on-azure-create-custom-web-deploy-packages-using-the-sitecore-azure-toolkit/).

###  WDP mapping configuration files

You can find config mapping files in the /configs folder of SAT. These types of configs describe resources that WDP will include after packaging. Configs use `JSON` format. 
There are two types of configs: `common` and `role specific`.  
`Common` config lists SCCPL packages that will be applied to each WDP. Here is an example of `common` config for AM type ARM templates:
```
{
    "sccpls":["Sitecore.Cloud.Common.sccpl", "Sitecore.Cloud.Search.sccpl", "Sitecore.Cloud.ApplicationInsights.sccpl", "Sitecore.Cloud.Thundercracker.sccpl"]
}
```  
Where as the other type describes `role specific` configurations. Here is example of `role specifc` config for AM type ARM templates:
```
{
    "scwdps":[
        {
            "role" : "appcd",
            "archiveXml" : "aM.App.archive.xml",
            "parametersXml": "aM.CD.parameters.xml",
            "sccpls" : ["Sitecore.Cloud.RoleSpecific_CD.sccpl", "Sitecore.Cloud.Redis_CD.sccpl", "Sitecore.Cloud.DisableAnalytics.sccpl", "Sitecore.Cloud.Thundercracker_CD.sccpl", "Sitecore.Cloud.Security_CD.sccpl"]
        },
        {
            "role" : "appcm",
            "archiveXml" : "aM.App.archive.xml",
            "parametersXml": "aM.CM.parameters.xml",
            "sccpls" : ["Sitecore.Cloud.RoleSpecific_CM.sccpl", "Sitecore.Cloud.DisableAnalytics.sccpl", "Sitecore.Cloud.HttpsRedirection.sccpl", "Sitecore.Cloud.IPSecurity.sccpl"]
        }
    ]
}
```
Example:  
  * The [common.app.packaging.config.json][common-app-packaging-config] file represents common configuration for deployment type that does not create and configure Sitecore databases. 
  * The [am.packaging.config.json][am-packaging-config] file represents configuration for AM type deployment. 

You can see more examples at [sitecore-on-azure/configs][config-examples] folder.

### MSDeploy configs

These `XML` files represent `MSDeploy manifest` (archive.xml) and `MSDeploy parameters` (parameters.xml) configurations. The `archive.xml` contains descriptions of SQL databases, SQL scripts and IIS application. Whereas `parameters.xml` has list of parameters that can be used to configure your application during the deployment process. For instance, set database connection strings or use `sitecore admin password` variable to set sitecore admin user password etc.

Example:  
  * The [aM.App.archive.xml][aM-App-archive] file describes MSDeploy manifest for AM type deployment.
  * The [aM.CM.parameters.xml][aM-CM-parameters] file describes MSDeploy parameters for `CM` role of AM type deployment.
  * The [aM.CD.parameters.xml][aM-CD-parameters] file describes MSDeploy parameters for `CD` role of AM type deployment.

You can see more MSDeploy configuration examples at [sitecore-on-azure/msdeployxmls][config-examples] folder. 

## Automate packaging process

Here is example PS code that can be used to assemble SoA WDP for AM deployment:
```
Start-SitecoreAzurePackaging -sitecorePath '.\Sitecore 8.2 rev. 161115_nodb.zip' `
                             -destinationFolderPath .\aM `
                             -cargoPayloadFolderPath .\resources\8.2.1\cargopayloads `
                             -archiveAndParameterXmlPath .\resources\8.2.1\msdeployxmls `
                             -commonConfigPath .\resources\8.2.1\configs\common.app.packaging.config.json `
                             -skuConfigPath .\resources\8.2.1\configs\aM0.packaging.config.json
```
>Note that example above uses `_nodb.zip` which has databases stripped out of Sitecore distributive as they are not necessary for AM deployment type.  
Tha's why [common.app.packaging.config.json][common-app-packaging-config] config has `Sitecore.Cloud.Security.sccpl` reference removed comparing to default configuration in `common.packaging.config.json` file.

You can use [packageSoA.ps1][package-soa-script] script as an example. 

## Upload WDP into Azure Blob

Once WDPs are ready, you need to make them available over HTTP for deployment MSDeploy process. I used [AzCopy](http://aka.ms/downloadazcopy) tool to upload them into my Azure Blob storage account.  
You can use [uploadSoAWdp2AzBlob.ps1][upload-wdp-script] example script to upload WDPs int your Azure Blob. 
The script creates `resourcelist.json` file with links to uploaded resources.

## Deploy Sitecore on Azure

To deploy SoA using desired ARM templates, follow instctions described at [Sitecore Azure Quickstart Templates](https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates) project.

[sat-get-started]: https://doc.sitecore.net/cloud/working_with_sitecore_azure_toolkit/overview/getting_started_with_sitecore_azure_toolkit
[sat-packaging]: https://doc.sitecore.net/cloud/working_with_sitecore_azure_toolkit/packaging/packaging_a_sitecore_solution_for_the_microsoft_azure_app_service
[common-app-packaging-config]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/configs/common.app.packaging.config.json" | relative_url }}
[am-packaging-config]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/configs/am.packaging.config.json" | relative_url }}
[config-examples]: https://github.com/ivansharamok/Sitecore-Azure-Quickstart-Templates/tree/master/Sitecore%208.2.1
[aM-App-archive]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/msdeployxmls/aM.App.archive.xml" | relative_url }}
[aM-CM-parameters]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/msdeployxmls/aM.CM.parameters.xml" | relative_url }}
[aM-CD-parameters]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/msdeployxmls/aM.CD.parameters.xml" | relative_url }}
[package-soa-script]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/ps/packageSoA.ps1" | relative_url }}
[upload-wdp-script]: {{ "/resources/media/2016-12-10-customize-sitecore-azuretoolkit-deployment/ps/uploadSoAWdp2AzBlob.ps1" | relative_url }}