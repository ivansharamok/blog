# MSDeploy Sitecore installation using SolrCloud with SwitchOnRebuild index

>This article was written using Sitecore 8.2.1

This article references resources from [Sitecore Azure Toolkit](https://dev.sitecore.net/Downloads/Sitecore_Azure_Toolkit/1x/Sitecore_Azure_Toolkit_100.aspx) to create configuration packages and assemble MSDeploy package.
Refer to blog posts by Bas Lijten to better understand the process of [creating custom configuration pacakages (SCCPL)](http://blog.baslijten.com/sitecore-on-azure-create-custom-web-deploy-packages-using-the-sitecore-azure-toolkit/) 
and [MSDeploy package catered to on-prem installation](http://blog.baslijten.com/use-the-sitecore-azure-toolkit-to-deploy-your-on-premises-environment/).  

## Create custom SCCPL configurations

Refer to [this article](http://blog.baslijten.com/sitecore-on-azure-create-custom-web-deploy-packages-using-the-sitecore-azure-toolkit/) for more details on how to create custom SCCPL configurations.
* `Sitecore.OnPrem.Common.sccpl` configuration  
This configuration adds `/App_Data` folder to website root directory and sets Sitecore's `dataFolder` setting to point to it.  
![](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/Sitecore-onprem-common-folder-structure.PNG?raw=true)  
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/Sitecore.OnPrem.Common.zip) example configuration structure for this package.

* `Solr.DataIndexes.Enabled.sccpl` configuration  
This configuration contains instructions to disable config files for Lucene `sitecore_core_index`, `sitecore_master_index`, `sitecore_web_index` and enable necessary Solr configs for these indexes.  
![](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/solr-dataindexes-enabled-config-structure.PNG?raw=true)  
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/Solr.DataIndexes.Enabled.zip) example configuration structure for this package.  

* `Solr.DataIndexes.SwitchOnRebuild.Enabled.sccpl` configuration  
This configuration sets Solr SwitchOnRebuild index for data indexes.  
![](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/solr-dataindexes-switchonrebuild-enabled-config-structure.PNG?raw=true)  
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/Solr.DataIndexes.SwitchOnRebuild.Enabled.zip) example configuration structure for this package.  

* `SolrCloud.DataIndexes.Reuse.ScItems.Collection.sccpl` configuration  
This configuration contains patch config files to set reusable Solr collection `scitems` for all data indexes.  
![](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/solrcloud-dataindexes-reuse-scitems-collection.PNG?raw=true)  
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/SolrCloud.DataIndexes.Reuse.ScItems.Collection.zip) example configuration structure for this package.  
>I use scripts to quickly standup SolrCloud instance with `scitems` and `scitems_swap` collections. That's why I created a separate SCCPL configuration with hard coded collection names.  
Ideally you would set collection names via parameters for your MSDeploy package.  

* `Sitecore.Security.SetAdminPassword.sccpl` configuration  
This configuration includes SQL script to set custom `sitecore\admin` user password when you install MSDeploy package.  
![](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/sitecore-security-setadminpassword.PNG?raw=true)  
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/Sitecore.Security.SetAdminPassword.zip) example configuration structure for this package.  
>You can get `SetSitecoreAdminPassword.sql` file from `Sitecore.Cloud.Security.sccpl` package distributed with Sitecore Azure Toolkit.


## Create config files for SCCPL assembly

* /configs/common.packaging.config.json  
```JSON
{
  "sccpls":["Sitecore.OnPrem.Common.sccpl", "Sitecore.Cloud.RoleSpecific_Single.sccpl", "Sitecore.Security.SetAdminPassword.sccpl"]
}
```
>This configuration assumes that you aim to install Sitecore XP on dev local machine. If you use `reporting.apikey` setting in /ConnectionStrings.config file, then remove `Sitecore.Cloud.RoleSpecific_Single.sccpl` configuration reference.  
You can find `Sitecore.Cloud.RoleSpecific_Single.sccpl` package in resources of Sitecore Azure Toolkit distribution file.

* /configs/solrcloud.switchonrebuild.config.json  
```JSON
{
  "scwdps":[
    {
      "role" : "xp-solrcloud",
      "archiveXml" : "solrcloud.switchonrebuild.archive.xml",
      "parametersXml": "solrcloud.switchonrebuild.parameters.xml",
      "sccpls" : ["Solr.DataIndexes.Enabled.sccpl", "Solr.DataIndexes.SwitchOnRebuild.Enabled.sccpl", "SolrCloud.DataIndexes.Reuse.ScItems.Collection.sccpl"]
    }
  ]
}
```

## Create MSDeploy parameters and archive files

* /msdeployxmls/solrcloud.switchonrebuild.parameters.xml  
```xml
<parameters>
  ..........
  <parameter name="Solr Endpoint" description="Sitecore SolrCloud Config" tags="Hidden,NoStore">
    <parameterEntry kind="XmlFile" scope="App_Config\\Include\\.ContentSearch\.Solr\.DefaultIndexConfiguration\.config$" match="//settings/setting[@name='ContentSearch.Solr.ServiceBaseAddress']/@value" />
  </parameter>
</parameters>
```
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/solrcloud.switchonrebuild.parameters.xml) complete example parameters.xml file.  

* /msdeployxmls/solrcloud.switchonrebuild.archive.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<sitemanifest MSDeploy.ObjectResolver.createApp="Microsoft.Web.Deployment.CreateApplicationObjectResolver" MSDeploy.ObjectResolver.dirPath="Microsoft.Web.Deployment.DirPathObjectResolver" MSDeploy.ObjectResolver.filePath="Microsoft.Web.Deployment.FilePathObjectResolver">
  <dbDacFx path="Sitecore.Reporting.dacpac" databaseName="Sitecore.Reporting.dacpac" MSDeploy.databaseName="1" MSDeploy.MSDeployLinkName="Child2" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="..." MSDeploy.MSDeployObjectFlags="1" MSDeploy.MSDeployStreamRelativeFilePath="Sitecore.Reporting.dacpac" />
  <dbDacFx path="Sitecore.Core.dacpac" databaseName="Sitecore.Core.dacpac" MSDeploy.databaseName="1" MSDeploy.MSDeployLinkName="Child3" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="..." MSDeploy.MSDeployObjectFlags="1" MSDeploy.MSDeployStreamRelativeFilePath="Sitecore.Core.dacpac" />
  <dbDacFx path="Sitecore.Master.dacpac" databaseName="Sitecore.Master.dacpac" MSDeploy.databaseName="1" MSDeploy.MSDeployLinkName="Child4" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="..." MSDeploy.MSDeployObjectFlags="1" MSDeploy.MSDeployStreamRelativeFilePath="Sitecore.Master.dacpac" />
  <dbDacFx path="Sitecore.Web.dacpac" databaseName="Sitecore.Web.dacpac" MSDeploy.databaseName="1" MSDeploy.MSDeployLinkName="Child5" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="..." MSDeploy.MSDeployObjectFlags="1" MSDeploy.MSDeployStreamRelativeFilePath="Sitecore.Web.dacpac" />
  <dbFullSql path="SetSitecoreAdminPassword.sql" MSDeploy.MSDeployLinkName="Child10" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="...">
    .....
  </dbFullSql>
  <iisApp path="Website" MSDeploy.path="2" MSDeploy.MSDeployLinkName="Child1" MSDeploy.MSDeployKeyAttributeName="path" MSDeploy.MSDeployProviderOptions="...">
  .....
  </iisApp>
</sitemanifest>
```
[Download](./resources/media/script-sitecore-installatoin-using-solrcloud-with-switchonrebuild-index/solrcloud.switchonrebuild.archive.xml) complete example archive.xml file.  


## Create MSDeploy package

Assemble MSDeploy package:
```ps
Start-SitecoreAzurePackaging -sitecorePath 'C:\simRepo\Sitecore 8.2 rev. 161115.zip' -destinationFolderPath 'C:\wdps' -cargoPayloadFolderPath '.\customDeploy\cpls' -commonConfigPath '.\customDeploy\configs\common.packaging.config.json' -skuConfigPath '.\customDeploy\configs\solrcloud.switchonrebuild.config.json' -archiveAndParameterXmlPath '.\customDeploy\msdeployxmls'
```

## Set MSDeploy parameters

Create setParameter.xml file where you specify MSDeploy parameters values:  
```xml
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <setParameter name="Application Path" value="tst821" />
  <setParameter name="Sitecore Admin New Password" value="b" />
  <setParameter name="Core Admin Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_core;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Core Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_core;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Master Admin Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_master;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Master Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_master;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Web Admin Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_web;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Web Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_web;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Reporting Admin Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_reporting;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Reporting Connection String" value="Data Source=.\SQLEXPRESS;Initial Catalog=tst821_reporting;Integrated Security=False;User ID=sa;Password=12345" />
  <setParameter name="Analytics Connection String" value="mongodb://localhost:27017/tst821_analytics" />
  <setParameter name="Tracking Live Connection String" value="mongodb://localhost:27017/tst821_tracking_live" />
  <setParameter name="Tracking History Connection String" value="mongodb://localhost:27017/tst821_tracking_history" />
  <setParameter name="Tracking Contact Connection String" value="mongodb://localhost:27017/tst821_tracking_contact" />
  <setParameter name="Build Number" value="5" />
  <setParameter name="Solr Endpoint" value="http://localhost:8983/solr" />
</parameters>
```

## Deploy Sitecore using MSDeploy package and setParameter.xml file

>Command below assumes that `msdeploy` path is added to `Path` environment variable.
```ps
msdeploy -presync:runCommand="%SYSTEMROOT%\System32\inetsrv\appcmd add apppool /name:tst821 & %SYSTEMROOT%\System32\inetsrv\appcmd add site /name:tst821 /bindings:http://tst821.local:80 /physicalPath:C:\inetpub\wwwroot\tst821\Website & %SYSTEMROOT%\System32\inetsrv\appcmd set app tst821/ /applicationPool:tst821" -source:package="C:\wdps\Sitecore 8.2 rev. 161115_xp-solrcloud.scwdp.zip" -dest:auto,IncludeAcls='False' -verb:sync -disableLink:ContentExtension -disableLink:AppPoolExtension -disableLink:CertificateExtension -retryAttempts:2 -setParamFile:"customDeploy\solrcloud.msdeploy.setParameters.xml"
```

## Copy license.xml into /App_Data

Last thing to do is to copy your `license.xml` file into `/App_Data` folder and you should be good to go.  
Keep in mind that this example shows how to configure only 3 data indexes with Solr using SwitchOnRebuild index. If you want to switch all indexes to Solr, add necessary configurations to disable Lucene configs for those indexes and enable corresponding Solr configs.

>Note  
There is a bug in Solr provider in version 8.2.1 which does not allow you to create index collection aliases automatically via `ContentSearch.Solr.EnforceAliasCreation` setting.
If you want this feature, use patch [Sitecore.Support.124981](https://github.com/SitecoreSupport/Sitecore.Support.124981).