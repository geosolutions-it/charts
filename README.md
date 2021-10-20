# charts
HELM Charts by GeoSolutions
# Technical requirements
• minikube

• kubectl

• helm

• git

• yamllint

• yamale

• chart-testing ( ct )

# git clone
 `git clone https://github.com/geosolutions-it/charts.git -b develop`
 
# Setting up your environment
1. Start minikube by running the minikube start command:

 `minikube start`
 
2. Then, create a new namespace called geoserver-helm 

 `kubectl create namespace geoserver-helm`
 
#  Validating template generation locally with helm template

`helm template name chart-dir `

 `helm lint v0.1.0/`
 
 # Install our app using our Chart
 
 `helm install geoserver v0.1.0/ `
 # list our releases

helm list

# see our deployed components
`kubectl get all `


`kubectl get cm `

`kubectl get secret `

# value injection

`779  helm template geo geoserver/v0.1.0/  --set persistence.postgis.size=2Gi

  780  helm template geo geoserver/v0.1.0/  --set persistence.postgis.size=2Gi | grep 2Gi 
  
  781  helm template geo geoserver/v0.1.0/  --set persistence.postgis.size=4Gi | grep 2Gi 
  
  782  helm template geo geoserver/v0.1.0/  --set persistence.postgis.size=4Gi 
  783  helm template geo geoserver/v0.1.0/  --set persistence.postgis.size=16Gi | grep 16Gi 
  784  helm template geo geoserver/v0.1.0/  --set persistence.datadir.size=16Gi | grep 16Gi 
  785  helm template geo geoserver/v0.1.0/  --set postgis.user=newuser | grep newuser 
  786  helm template geo geoserver/v0.1.0/  --set postgis.env.user=newuser | grep newuser 
  787  helm template geo geoserver/v0.1.0/  --set images.repository=geosolutionsit/geoserver:gs-stable-2.20.x | image 
  788  helm template geo geoserver/v0.1.0/  --set images.repository=geosolutionsit/geoserver:gs-stable-2.20.x | grep images
  789  helm template geo geoserver/v0.1.0/  --set images.repository=geosolutionsit/geoserver:gs-stable-2.20.x 
  790  helm template geo geoserver/v0.1.0/  --set images.tag=gs-stable-2.20.x 
  791  helm template geo geoserver/v0.1.0/  --set images.tag=gs-stable-2.20.x | grep tag
  792  helm template geo geoserver/v0.1.0/  --set images.tag=gs-stable-2.20.x | grep gs-stable-2.20.x
  793  helm template geo geoserver/v0.1.0/  --set service.port=9081 | grep 9081
  794  helm template geo geoserver/v0.1.0/  --set secrets.master_password=newpasword | grep newpassword
  795  helm template geo geoserver/v0.1.0/  --set secrets.master_password=newpasword | grep newpasword `


 

