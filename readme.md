# Helm Chart Templates for Geoserver in Kubernetes
This project provides template Helm Charts for deploying a [Geoserver](http://geoserver.org/) application into Kubernetes.

The templates require your application to built into a [Docker image](https://github.com/geosolutions-it/docker-geoserver). 

This project provides the following files
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

