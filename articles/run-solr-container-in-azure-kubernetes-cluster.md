# Run Solr container in Azure Kubernetes cluster (AKS)
Consult [Kubernetes documentation][kube-doc] to learn more about it and `kubectl` options. Refer to Azure [AKS tutorial][aks-tutorial] for more details on the service.  
This exercise uses [Azure CLI][az-cli] commands.

>This exercise assumes you have created a docker image and made it available either through [Azure ACR][acr-article] or using other image hosting service.

>All commands in this article were tested using Bash on Windows available in Win 10 Fall Creators Update.

## Create Kubernetes cluster
This step follows instructions from [AKS tutorial][aks-tutorial] with minor tweaks. 

### Create resource group to host AKS service
```bash
az group create --name akstest --location westus2
```

### _Generate SSH keys [optional]_
Navigate to `.ssh` folder and execute `ssh-keygen`. Follow instructions to create ssh keys.
```bash
ssh-keygen -N P@ssword1 -f aks_id
```
This command will create `aks_id` and `aks_id.pub` files.

### Create AKS service
```bash
az aks create --resource-group akstest --name myK8sCluster --agent-count 1 --ssh-key-value ~/.ssh/aks_id.pub
```
The command takes several minutes to complete and creates several resources:
* Azure service principal for cluster authentication. You can find it in your Azure Active Directory service at App registrations blade. Once there select My Apps to limit output to your account principals.  
The principal gets also added to `~/.azure/acsServicePrincipal.json` file.
* `myK8sCluster` service that will be added to `akstest` group.
* `MC_<groupName>_<aksName>_<location>` group with all resources necessary for Managed Kubernetes cluster. In this example it will be `MC_akstest_myK8sCluster_westus2`.

### Install kubectl CLI
```bash
az aks install-cli
```

### Get AKS credentials
```bash
az aks get-credentials --resource-group akstest --name myK8sCluster
```
This command will merge Kubernetes cluster configuration into `~/.kube/config` file. You can view it by running command:
```bash
kubectl config view
```

## Deploy Solr container into AKS pod
Next step is to deploy application instance (in this example Solr pod) and service instance to allow communication with application pod.

### Deploy Solr application instance
Creat Kubernetes deployment manifest (`solr-app-deployment.yml`) with the following content. Make sure to modify `image` parameter to point to your container image.
```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: solr-app
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: solr-app
    spec:
      containers:
      - name: solr-app
        image: myregistry.azurecr.io/solrssl-flex:6.6.0
        command: ["create-basic-cores.sh"]
        ports:
        - containerPort: 8983
          name: solr
```
Deploy manafest using `kubectl`.
```bash
kubectl apply -f ./solr-app-deployment.yml
```
Verify that deployment is created:
```bash
kubectl get deployment
```
Verify that pod for solr application is created and running:
```bash
kubectl get pods
```
If pod gets an error, you can try to access its logs:
```bash
kubectl logs <podName>
```

### Deploy service load balancer instance
Create manifest file to describe service instance `solr-service.yml`. Type `LoadBalancer` creates an external IP for the service so that you can access it from outside of AKS.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: solr-app
  labels:
    app: solr-app
    tier: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 8983
    targetPort: 8983
  selector:
    app: solr-app
```
Deploy service into AKS cluster.
```bash
kubectl apply -f ./solr-service.yml
```
Verify that service is up and running and has external IP:
```bash
kubectl get services
```

## Populate managed index schema
Sitecore 9 requires managed-schema to be populated with fields before you can start indexing Sitecore items. You can do this by calling `/sitecore/admin/PopulateManagedSchema.aspx?indexes=all` service page.  

## _Install self-signed SSL cert into Win CA root [optional]_
This step is necessary if you use [Solr image that creates self-signed SSL cert][solrssl-flex]. 
Copy SSL cert from pod into your local machine:
```bash
kubectl cp <podName>:/opt/solr/server/etc/solr-ssl.keystore.jks ~/solr-ssl.keystore.jks
```
Copy cert from Ubuntu on Windows to your Windows file system:
```bash
cp ~/solr-ssl.keystore.jks /mnt/c/temp/solr-ssl.keystore.jks
```
Install SSL cert into Windows CA root using [install-solrssl.ps1](https://gist.github.com/ivansharamok/6d22cde83944117c349d247137f10100) PS script.

## _Use namespaces for different environments [optional]_
By default everything you create in your AKS cluster goes into `default` namespace. Kubernetes allows to isolate or group resources through [namespaces][kube-namespaces].  
### Create namespace for testing environment
Create manifest file (`namespace-testing.json`) that describes `testing` namespace.
```json
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "testing",
    "labels": {
      "name": "playground"
    }
  }
}
```
Deploy `testing` namespace into AKS cluster:
```bash
kubectl create -f namespace-testing.json
```
View available namespaces in your AKS cluster:
```bash
kubectl get namespace --show-labels
```
Now you can deploy apps and services into testing namespace of you AKS cluster by adding `--namespace testing` parameter to `kubectl` command.
```bash
kubectl apply -f ./solr-app-deployment.yml --namespace testing
```


[kube-doc]: https://kubernetes.io/docs/home/
[aks-tutorial]: https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough
[acr-article]: ./run-your-container-in-azure.md
[az-cli]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
[solrssl-flex]: ./flexible-solr-container-image-for-sitecore.md
[kube-namespaces]: https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/