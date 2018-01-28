---
layout: post
title: Solr cloud in AKS (dev)
tags: indexing docker kubernetes
categories: solr containers azure
date: 2018-01-27
---

* TOC
{:toc}

This example describes how to run Solr cloud cluster + zookeeper ensemble in [Kubernetes on Azure (AKS)][aks-doc]. Since Solr cloud relies on Zookeeper to manage configuration and data storage, two containers need to be used in this example: [Zookeeper (Zk)][zk-doc] and [Solr][solr-doc].
>Provided example was tested with AKS cluster version 1.8.2, Solr 6.6.2 and Zookeeper 3.4.11.

>TL;TR  
Scripts and configs: 
* [Dockerfile Zk][dockerfile-zk]
* [scripts Zk][scripts-zk]
* [Dockerfile Solr][dockerfile-solr]
* [configs Solr][configs-solr]

## Create Kubernetes cluster
Follows instructions in [AKS tutorial][aks-tutorial] or [my previous post][solr-in-aks]. I used AKS cluster version 1.8.2.

## Build Zookeeper Docker image
Using [Dockerfile Zk][dockerfile-zk] build Zk Docker image and upload to your Docker image repository that is accessible to AKS. I used [Azure Container Registry (ACR)][acr-doc].

## Build Solr Docker image
Using [Dockerfile Solr][dockerfile-solr] build Solr Docker image and upload to your Docker image repository that is accessible to AKS. In this example - ACR.

## Configure AKS secret to pull images
If you store images in a private registry, you need to create a Kubernetes secret with credentials that will be used to pull images.

### _[Optional] Create service principal to pull image from ACR_
If you use ACR to host Docker images, you may want to create a service principle account that would be used to pull images from the registry. See full example at [AKS docs][acr-auth].
```bash
ACR_REGISTRY_ID=$(az acr show --name myAcrName --query id --output tsv)
SP_PASSWORD=$(az ad sp create-for-rbac --name my-acr-sp --role Reader --scopes $ACR_REGISTRY_ID --query password --output tsv)
CLIENT_ID=$(az ad sp show --id http://my-acr-sp --query appId --output tsv)
echo "Service principal ID: $CLIENT_ID"
echo "Service principal password: $SP_PASSWORD"
```  

>Record CLIENT_ID and SP_PASSWORD values as they need to be used to create a Kubernetes secret in order to pull images from ACR.

### Create secret
Replace variables wrapped in `<>` in the following command with corresponding values from your environment.
```bash
kubectl create secret docker-registry acr-auth --docker-server <acr-login-server> --docker-username <CLIENT_ID> --docker-password <SP_PASSWORD> --docker-email <email-address>
```

Verify that your `acr-auth` secret got created in AKS.
```bash
kubectl get secret
```

## Create Zookeeper ensemble
Use [zookeeper-ephemeral.yaml][zk-yaml] to create Zk ensemble in AKS.
```bash
kubectl apply -f zookeeper-ephemeral.yaml
```

Check whether Zk pods got created.
```bash
kubectl get pods
```

## Create Solr cloud cluster
Use [solrcloud-ephemeral.yaml][solr-yaml] to create Solr cluster in AKS.
```bash
kubectl apply -f solrcloud-ephemeral.yaml
```
Verify that pods got created and running.

## Test Solr cloud access
Make sure sure `solrsvc` service of type `LoadBalancer` got created and assigned an external IP. It may take a few minutes for Azure to allocate and assign an IP to the service.
```bash
kubectl get svc
```

Use load balancer IP to access Solr instance: `http://<LB_IP>:8983/solr`

## Creating indexes
To make sure everything is running fine, you can create a sample index using one of default configsets supplied with Solr dist (e.g. `basic_configs`).

### Upload *basic_configs* configuration into Zk
In order to create an index in Solr cloud, you must have a configuration uploaded into Zk.

#### Get Solr and Zk pods names
```bash
kubectl get pods
```
For example, pod names are `solrapp-0` and `zk-0`.

#### Get Zk instance full name
```bash
kubectl exec zk-0 -- hostname
kubectl exec zk-0 -- sh -c 'echo $(hostname -d)'
```

#### Upload configset from a known path into Zk
Each Solr distro has a few predefined configsets located at `/opt/solr/server/solr/configsets` path.
```bash
kubectl exec solrapp-0 -- solr zk -upconfig -d /opt/solr/server/solr/configsets/basic_configs -n basic -z zk-0.zk.default.svc.cluster.local:2181
```

#### Create sample index
```bash
curl http://<solr-host>:8983/solr/admin/collections?action=CREATE -d name=basic -d numShards=3 -d replicationFactor=2 -d maxShardsPerNode=2 -d collection.configName=basic
```

## Tips & tricks
Usefull commands and troubleshooting tips.

### Create short alias for kubectl command
To minimize number of key strokes to execute AKS commands, consider creating a shorter alias for `kubectl` command.
```bash
alias k=kubectl
k get pods
```

### Assign existing service principal to Azure resource
```bash
ACR_ID=$(az acr show --name isregistry --query id -o tsv)
$ az role assignment create --assignee <SP_ID> --role 'Reader' --scope $ACR_ID
```

### Verify service principal is assigned to the ACR
```bash
ACR_ID=$(az acr show --name isregistry --query id -o tsv)
az role assignment list --scope $ACR_ID -o table
```

### Get events for specific pod
```bash
kubectl get ev | grep <podName>
```

### Get Zk container mode
```bash
kubectl exec <podName> -- bin/zkServer.sh status
```

### Get container hostname and DNS
```bash
kubectl exec <podName> -- sh -c hostname
kubectl exec <podName> -- sh -c 'echo $(hostname -d)'
```

## Resources
* Zookeeper on CentOS container image. If you want to use [CentOS](https://www.centos.org/) container for Zk, take a look into [paulbrown/zookeeper example][zk-centos].
* [Solr cloud on local Docker instance](https://hub.docker.com/r/hardikdocker/solrcloud-zookeeper-docker/).
* [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
* [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/).

[aks-doc]: https://docs.microsoft.com/en-us/azure/aks/
[zk-doc]: https://zookeeper.apache.org/
[solr-doc]: https://lucene.apache.org/solr/
[acr-doc]: https://docs.microsoft.com/en-us/azure/container-registry/
[zk-centos]: https://hub.docker.com/r/paulbrown/zookeeper/
[acr-auth]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aks?#access-with-kubernetes-secret
[solr-in-aks]: {% post_url 2017-11-07-run-solr-container-in-azure-kubernetes-cluster %}
[zk-yaml]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/kube/zookeeper-ephemeral.yaml" | relative_url }}
[solr-yaml]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/kube/solrcloud-ephemeral.yaml" | relative_url }}
[dockerfile-zk]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/zk/Dockerfile" | relative_url }}
[scripts-zk]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/zk" | prepend: site.github_blog_root }}
[dockerfile-solr]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/solr/Dockerfile" | relative_url }}
[configs-solr]: {{ "/resources/media/2018-01-27-solrcloud-in-aks-dev/solr/scripts" | prepend: site.github_blog_root }}