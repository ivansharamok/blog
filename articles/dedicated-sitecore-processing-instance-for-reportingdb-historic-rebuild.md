# Dedicated Sitecore processing instance for reporting database historic rebuild

Here is an idea how you can have a dedicated Sitecore processing instance to run reporting database rebuild or Path Analyzer map rebuild off of a hidden mongodb secondary node.  
Why? - to let primary aggregation/processing instances and mongodb replica set to handle live data and have a separate instance to read historic data from a hidden secondary mongodb node when needed.

## Configure processing instance

First, you need to configure Sitecore instance as a [processing/aggregation role](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/xdb/configuring_servers/configure_a_processing_server).

## Configure connection string to hidden node
Add a hidden node to your mongodb replica set.  
For dev and testing purposes you can use [CreateMongoReplicaSet-2nod-1arb-1hid.cmd](https://gist.github.com/ivansharamok/93c9bca5a0473e1bb8cef3e15a4efc9d/raw) script to stand up mongodb replica set with a hidden node:  
Then add a connection string to `/App_Config/ConnectionStrings.config` pointing to the hidden node. Make sure you add `?slaveok=true` to the connection string to allow data provider to read from the hidden node.
```xml
<connectionStrings>
  .....
  <add name="analytics.hidden" connectionString="mongodb://localhost:27020/sc82_analytics?slaveok=true" />
</connectionStrings>
```

## Configure aggregation subsystem to use custom collectionData
Add another `collectionData` configuration to `aggregation` section and set it to use connection string to hidden mongodb node. Then set aggregation subsystem processes relevant to historic rebuild to use custom `collectionData` configuration.
```xml
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/" xmlns:set="http://www.sitecore.net/xmlconfig/set/">
  <sitecore>
    <aggregation patch:source="Sitecore.Analytics.Processing.Aggregation.config">
      <aggregationContexts>
        <interaction>
          <history>
            <Source set:ref="aggregation/collectionDataHidden" />
          </history>
        </interaction>
        <pathAnalyzer patch:source="Sitecore.PathAnalyzer.Processing.config">
          <history>
            <Source set:ref="aggregation/collectionDataHidden" />
          </history>
        </pathAnalyzer>
      </aggregationContexts>
      <!-- Custom Collection Data for hidden mongodb node -->
      <collectionDataHidden type="Sitecore.Analytics.Aggregation.MongoDbCollectionDataProvider, Sitecore.Analytics.MongoDB" singleInstance="true">
        <param desc="connectionStringName">analytics.hidden</param>
      </collectionDataHidden>
      <historyTaskManager>
        <CollectionData set:ref="aggregation/collectionDataHidden" />
      </historyTaskManager>
      <historyWorker>
        <CollectionData set:ref="aggregation/collectionDataHidden" />
      </historyWorker>
    </aggregation>
  </sitecore>
</configuration>
```

Download example [Dedicated.Processing.ReportingDb.Historic.Rebuild.config](https://github.com/ivansharamok/Content/blob/master/articles/resources/media/dedicated-sitecore-processing-instance-for-reportingdb-historic-rebuild/Dedicated.Processing.ReportingDb.Historic.Rebuild.config) patch config file.

## Configuration of processing instances
Keep in mind that above configuration steps would set you up with Sitecore processing instance that is capable to run reporting database rebuild off of a hidden mongodb node but it does not aggregate live analytical data that is being written to your xDB. Before you run histori rebuild of your reporting database, you need to make sure that primary processing/aggregation instance and dedicated processing/aggregation instance for history rebuilds are configured to point to the same `reporting` and `reporting.secondary` databases. In other words these connection strings must be present in all processing/aggregation instances and point to the same databases:
```xml
<connectionStrings>
  .....
  <add name="reporting" connectionString="Data Source=.\SQLEXPRESS;Initial Catalog=sc82_reporting;Integrated Security=False;User ID=sa;Password=example" />
  <add name="reporting.secondary" connectionString="Data Source=.\SQLEXPRESS;Initial Catalog=sc82_reporting_secondary;User ID=sa;Password=example" />
</connectionStrings>
```

When reporting database historic rebuild is required, you can start it from dedicated reporting historic rebuild instance and let your primary servers work on live data. When rebuild is finished, [reconfigure reporting connection strings](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/xdb/server_considerations/walkthrough_rebuilding_the_reporting_database#_Reconfigure_reporting_connections) on all processing/aggregation instances`.