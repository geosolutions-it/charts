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
git clone https://github.com/geosolutions-it/charts.git -b develop

# Setting up your environment
1. Start minikube by running the minikube start command:
 `minikube start`
2. Then, create a new namespace called geoserver-helm :
 `kubectl create namespace geoserver-helm`
#  Validating template generation locally with helm template
`helm template name chart-dir `
 `helm lint v0.1.0/`

