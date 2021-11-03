# Helm Chart Templates for Geoserver in Kubernetes
This project provides template Helm Charts for deploying a [Geoserver](http://geoserver.org/) application into Kubernetes.

The templates require your application to built into a [Docker image](https://github.com/geosolutions-it/docker-geoserver). 


This project provides the following files:

| File                                              | Description                                                           |
|---------------------------------------------------|-----------------------------------------------------------------------|  
| `charts/geoserver/v0.1.0/Chart.yaml`                    | The definition file for your application                           | 
| `charts/geoserver/v0.1.0/values.yaml`                   | Configurable values that are inserted into the following template files      | 
| `charts/geoserver/v0.1.0/templates/configmap.yml` | Template to configure your application deployment.                 |
| `charts/geoserver/v0.1.0/templates/ingress.yaml`     | Template to configure your application deployment.                 | 
| `charts/geoserver/v0.1.0/templates/persistence.yaml`        | Template to configure your application deployment.                 | 
| `charts/geoserver/v0.1.0/templates/hpa.yaml`            | Template to configure your application deployment.                 | 
| `charts/geoserver/v0.1.0/templates/secrets.yaml`          | Template to configure your application deployment.                 | 
| `charts/geoserver/v0.1.0/templates/serviceaccount.yaml`   | Template to configure your application deployment. 
| `charts/geoserver/v0.1.0/templates/service.yaml`          | Template to configure your application deployment. 
| `charts/geoserver/v0.1.0/templates/statefulset.yaml`      | Template to configure your application deployment. 
| `charts/geoserver/v0.1.0/templates/NOTES.txt`           | Helper to enable locating your application IP and PORT        | 

## Prerequisites
1. You have a Kubernetes cluster  
  This could be one hosted by a cloud provider or running locally, for example using [Minikube](https://kubernetes.io/docs/setup/minikube/)
2. You have kubectl installed and configured for your cluster  
  The [Kuberenetes command line](https://kubernetes.io/docs/tasks/tools/install-kubectl/) tool, `kubectl`, is used to view and control your Kubernetes cluster.
3. You have the Helm command line installed  
   [Helm](https://docs.helm.sh/using_helm/) provide the command line tool and backend service for deploying your application using the Helm chart.
   These charts are compatible with Helm TO BE MODIFED 

### Setting the `image.repository` parameter

In order to change the `image.repository` parameter, open the `charts/geoserver/v0.1.0/values.yaml`  file and change the following entry:  

```sh
image:
  repository: geosolutionsit/geoserver
```
## Configuring the Chart for your Application
The following table lists the configurable parameters of the template Helm chart and their default values.

| Parameter                  | Description                                     | Default                                                    |
| -----------------------    | ---------------------------------------------   | ---------------------------------------------------------- |
| `replicaCount`             | replicaCount                                    | 1
| `image.repository`         | image repository                                | `geosolutionsit/geoserver`                                 |
| `image.tag`                | Image tag                                       | `latest`                                                    |
| `image.pullPolicy`         | Image pull policy                               | `IfNotPresent`                                                   |
| `imagePullSecrets`   |            |                             |
| `serviceAccount.create`    | Specifies whether a service account should be created      | `true`           |
| `serviceAccount.annotations` | Annotations to add to the service account         | `{}`                                                     |
| `serviceAccount.name`       | The name of the service account to use.    | `If not set and create is true, a name is generated using the fullname template`                                                 |
| `service.port`             | TCP Port for this service                       | 80                                                      |
| `service.type`             | Type for this service                       | ClusterIP                                                    |
| `persistence.root.size`  | persistencesize                         | `1Gi`                                                     |
| `persistence.coverages.size`      | -----                            | `1Gi`                                                     |
| `persistence.datadir.size`      | -----                            | `1Gi`                                                     |
| `persistence.memdumps.size`      | -----                            | `1Gi`                                                     |
| `persistence.postgis.size`      | -----                            | `1Gi`                                                     |
| `secrets.master_password`      | -----                            | `geoserver`                                                     |
| `secrets.postgis_password`      | -----                            | `geoserver`                                                     |
## Using the Chart to deploy your Application to Kubernetes




## Uninstalling your Application
