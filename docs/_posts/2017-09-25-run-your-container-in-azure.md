---
layout: post
title: Run your container in Azure
tags: indexing docker
categories: solr containers azure
date: 2017-09-25
---

* TOC
{:toc}

I can run [Solr+SSL docker container][solr+ssl] and a bit more [flexible Solr+SSL container][flexible solr+ssl] with Sitecore indexes on my local machine. In this exercise I push my local Docker image into [Azure Container Registry](https://azure.microsoft.com/en-us/services/container-registry/) (ACR) and then create [Azure Container Instance](https://azure.microsoft.com/en-us/services/container-instances/) (ACI) to run my container in Azure.

>You need [Azure CLI] 2.0 to run scripts in this article. The version should be >= 2.0.13.

>I used [this tutorial][acr tutorial] to experiment with ACR and ACI.

## Create Azure Container Registry
First, create ACR in your Azure subscription to hold your container images.

```azure-cli
az acr create -n myregistry -g mygroup --location westcentralus --sku Managed_Basic --admin-enabled true
```
>Complete PowerShell script [create-acr.ps1]

>At the time I used Azure containers not all regions supported Managed sku options. Most regions have `Basic` (a.k.a. Classic) storage for ACR which is tied to a storage account. If you want to use Managed storage, then explore which regions support it. I found a few: `eastus`, `westcentralus`.  
`Basic` (Classic) storage option for ACR does not allow to delete uploaded images. `Managed` options didn't seem to have this limitation.

Once the registry is created its full name should be `myregistry.azurecr.io`.

## Tag image to be pushed into ACR
To upload a container image into your ACR, you have to tag it with full ACR name first. I used [flexible Solr+SSL][flexible solr+ssl] image for this.
```docker
docker tag solrssl-flex:6.6.0 myregistry.azurecr.io/solrssl-flex:6.6.0
```
Run `docker images` to make sure your new tagged image is listed.

## Push image into ACR
This is done by means of `docker push` command.
```docker
docker push myregistry.azurecr.io/solrssl-flex:6.6.0
```
>Complete PowerShell script example [push-image2acr.ps1].

## Create Azure Container Instance from ACR image
To create container instance in Azure from ACR image run this command:
```powershell
$acrPwd=$(az acr credential show -n myregistry --query "passwords[0].value")
az container create -g mygroup -n mysolr --image myregistry.azurecr.io/solrssl-flex:6.6.0 --cpu 1 --memory 1.5 --registry-password $acrPwd --ip-address public --port 8983
```
>If you want to pass a command line to be executed at the time container instance is created you can that via ` --command-line 'my-script.sh'` parameter.

>Complete PowerShell script [deploy-aci-from-acr.ps1].


[solr+ssl]: {% post_url 2017-09-20-run-solr+ssl-in-docker-container-with-sitecore-indexes %}
[flexible solr+ssl]: {% post_url 2017-09-24-flexible-solr-container-image-for-sitecore %}
[acr tutorial]: https://docs.microsoft.com/en-us/azure/container-instances/container-instances-tutorial-prepare-app
[Azure CLI]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
[create-acr.ps1]: https://gist.github.com/ivansharamok/15692dcfb9ed03552d9e0ebb30d089ca
[push-image2acr.ps1]: https://gist.github.com/ivansharamok/acc36673c1be6d73c32fb87472674001
[deploy-aci-from-acr.ps1]: https://gist.github.com/ivansharamok/7bd14e3c9b733f3c1a607a725d42c433