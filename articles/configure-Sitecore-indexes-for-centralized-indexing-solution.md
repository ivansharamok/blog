# Configure Sitecore indexes for centralized indexing solution

That's a thought on how one should approach configuration of Sitecore indexes when using centralized indexing solution (e.g. Solr or Azure Search).
I use Solr as primary example in this article.

## How index relays to indexing strategy

Each index in Sitecore configuration should have an indexing strategy (defined under `/contentSearch/indexConfigurations/indexUpdateStrategies` config section) to define when and how indexing operations happen.  

For example, default `sitecore_master_index` uses `syncMaster` strategy. It kicks off indexing as soon as any CRUD operation is applied to an item. 
```xml
        <index id="sitecore_master_index" type="Sitecore.ContentSearch.SolrProvider.SwitchOnRebuildSolrCloudSearchIndex, Sitecore.ContentSearch.SolrProvider">
          .....
          <strategies hint="list:AddStrategy">
            <strategy ref="contentSearch/indexConfigurations/indexUpdateStrategies/syncMaster" />
          </strategies>
          .....
        </index>
```
You can imagine that during high number of CRUD operations (e.g. custom job pulls data from external data source), this strategy may overwhelm application server as it will fight for resources to run indexing jobs. 
A way to mitigate this effect is to use `intervalAsyncMaster` strategy. It runs per defined period rather than reacts to immediate CRUD operations.  
For second example I'll use `sitecore_web_index` that relies on `onPublishEndAsync` strategy. This strategy kicks off indexing operation when `PublishEnd` event occurs.
```xml
        <index id="sitecore_web_index" type="Sitecore.ContentSearch.SolrProvider.SwitchOnRebuildSolrCloudSearchIndex, Sitecore.ContentSearch.SolrProvider">
          .....
          <strategies hint="list:AddStrategy">
            <strategy ref="contentSearch/indexConfigurations/indexUpdateStrategies/onPublishEndAsync" />
          </strategies>
          .....
        </index>
```

## How EventQueue plays a role

Now lets imagine that we have distributed Content Management (CM) and Content Delivery (CD) environments. Let's say there are CM1, CM2 instances and CD1, CD2 instances.  
When content author modifies an item on CM1 instance (i.e. `sitecore_master_index` is involved), the item will get indexed according to indexing strategy (giving our example it's `syncMaster` strategy). 
The change will be pushed to the index that is managed by Solr. When the change happens, all other instances get notified via `EventQueue` (EQ). Each instance reads EQ entries and replays the events when applicable. 
In this example, CM2 would read the item changed event(s) and replay it locally. This will trigger an indexing operaion on CM2 instance. Since the index is managed by Solr, the indexed data will be sent to Solr. 
However, the same data were already submitted to Solr when the indexing operation happened on CM1 instance.  
The same is true for `sitecore_web_index`. When a publishing operation occurs, the index updates will be sent to Solr from each Sitecore instance that has `sitecore_web_index` defined.  
As a result Sitecore instances maybe sending the same indexed data multiple times to Solr instance.

## How to stop sending duplicate data to indexing solution

We established that indexing strategy is responsible for triggering indexing operations. The strategy is defined in the configuration of the index. Therefore, one can change it when it's needed. 
Likely, Sitecore provides several indexing strategies. One of those is `manual` strategy. It does not trigger incremental index updates. It can run index update when the index rebuild is called explicitly (e.g. via UI tools).
```xml
<!-- AUTOMATIC INDEXING DISABLED STRATEGY 
     Every index that uses this strategy must be manually rebuilt. 
-->
<manual type="Sitecore.ContentSearch.Maintenance.Strategies.ManualStrategy, Sitecore.ContentSearch" />
```
In our example we can set `sitecore_master_index` to use `manual` strategy on CM2 instance. This will make CM1 the only instance that can push indexed data to Solr. 
For CD instances, we can set `sitecore_web_index` to use `manual` strategy on CD1, CD2 and CM2 as the same index is already defined on CM1 and uses the same Solr instance.

The downside of such configuration is that your CM environment has 2 instances with different configurations. It would require separate deployment process for CM1 and CM2. One solution could be to use a dedicated indexing instance.

## Dedicated indexing instance

You can introduce an indexing role that would run all indexing operations for your Sitecore environments. It could be a single instance for all environments or there could be one indexing instance for each environment.
The configuratoin of indexing instance is rather simple. You make sure that all necessary indexes are defined and configured in the indexing instance. 
The same indexes should be set to use `manual` strategy for all other Sitecore instances (e.g. CM, CD).

>It is a common practice to have a job instance that runs application custom jobs. This instance can be an ideal candidate to run all indexing jobs too. 
Though, it all depends on how resource intence your custom jobs are and how often indexing operations happen.