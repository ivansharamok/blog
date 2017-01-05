# Configure BasicAuthentication for Solr provider with Sitecore

>Approach in this article has been tested with Sitecore 8.2.1 and Solr 6.3.0

## Configure Solr basic authentication plugin

Refer to official [Basic Authentication Plugin](https://cwiki.apache.org/confluence/display/solr/Basic+Authentication+Plugin) article to understand how it can be configured.  

>Note  
Prior to Solr 6.3.0 there is an issue with `blockUnknown` property described in [SOLR-9188](https://issues.apache.org/jira/browse/SOLR-9188).

Steps below provide example configuration of basic authentication plugin for Solr 6.3.0.

### Create /security.json file

This example configures basic authentication with user `solr` and password `SolrRocks`

```json
{
    "authentication": {
        "blockUnknown": true,
        "class": "solr.BasicAuthPlugin",
        "credentials": {
            "solr": "IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c="
        }
    },
    "authorization": {
        "class": "solr.RuleBasedAuthorizationPlugin",
        "permissions": [
            {
                "name": "security-edit",
                "role": "administrator"
            }
        ],
        "user-role": {
            "solr": "administrator"
        }
    }
}
```

>Note  
The `authorization` section in the example above does not provide sufficient permissions but rather provided as an example how it can be configured.

### Upload /security.json to Zookeeper

Execute one of the following commands to upload /security.json file into your Solr instance.

#### Any Solr 5.x or 6.x

```bat
server\scripts\cloud-scripts\zkcli.bat -zkhost localhost:9983 -cmd put /security.json security.json
```

#### Simplified command for Solr 6.3.0

```bat
bin\solr zk cp file:security.json zk:security.json -z localhost:9983
```

## Configure Sitecore search provider basic authentication

Solr provider for Sitecore exposes `solrHttpWebRequestFactory` configuration section that allows you to configure corresponding C# class that handles Solr request authentication.
To configure Solr provider to use basic authentication patch `solrHttpWebRequestFactory` section:  
```xml
  <sitecore>
    <contentSearch>
      <indexConfigurations>
        <solrHttpWebRequestFactory set:type="HttpWebAdapters.BasicAuthHttpWebRequestFactory, SolrNet">
          <param hint="username">solr</param>
          <param hint="password">SolrRocks</param>
        </solrHttpWebRequestFactory>
      </indexConfigurations>
    </contentSearch>
  </sitecore>
```

>Note  
There is a bug in Solr provider for Sitecore 8.2.1 which does not allow authentication to work properly.
Use [Sitecore.Support.141324](https://github.com/SitecoreSupport/Sitecore.Support.141324) patch to work around this issue.  

>Note  
There is a bug in Solr provider in version 8.2.1 which does not allow you to create index collection aliases automatically via `ContentSearch.Solr.EnforceAliasCreation` setting.
If you want this feature, use patch [Sitecore.Support.124981](https://github.com/SitecoreSupport/Sitecore.Support.124981).