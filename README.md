# GeoSolutions Helm Charts

## Overview

This repository contains Helm charts for:
- **[GeoServer](geoserver/latest/)** - Open-source geospatial server for sharing, processing, and editing geospatial data
- **[MapStore](mapstore/latest/)** - Web mapping framework for creating, managing, and sharing maps and mashups

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Repository Structure

```
charts/
├── .github/workflows/     # CI/CD pipelines
│   ├── helm-ci.yaml      # Validation and testing
│   └── release.yaml      # Automated releases to S3
├── geoserver/latest/     # GeoServer Helm chart
└── mapstore/latest/      # MapStore Helm chart
```

## Chart Registry

Charts are hosted on AWS S3:
- **Bucket**: `s3://geosolutions-charts` (eu-west-2)
- **Public URL**: https://charts.geosolutionsgroup.com
- **Authentication**: AWS [OIDC](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws?utm_source=chatgpt.com)

## Quick Start

### Adding the Helm Repository

```bash
# Add the GeoSolutions chart repository
helm repo add charts https://charts.geosolutionsgroup.com/charts

# Update your local chart repository cache
helm repo update

# List available GeoServer and MapStore chart versions
helm search repo charts/geoserver --versions
helm search repo charts/mapstore --versions

# Example: use GeoServer chart version 3.0.2
helm install geoserver charts/geoserver --version 3.0.2
helm upgrade geoserver charts/geoserver --version 3.0.2
```

The `--version 3.0.2` examples require the chart published at [https://charts.geosolutionsgroup.com/charts](https://charts.geosolutionsgroup.com/charts), added above as `charts`. Helm cannot select that repository version when installing from the local `./geoserver/latest` source directory.

### Installing Charts

#### GeoServer

```bash
# Install with default values
helm install geoserver charts/geoserver

# Install with custom values
helm install geoserver charts/geoserver \
  --set admin_password=MySecurePassword \
  --set persistence.datadir.size=10Gi
```

#### MapStore

```bash
# Install with default values
helm install mapstore charts/mapstore

# Install with custom values
helm install mapstore charts/mapstore \
  --set ingress.host=mapstore.example.com \
  --set persistence.size=10Gi
```

## Configuration

Each chart has its own `values.yaml` file with configurable parameters. See individual chart documentation for details:

- [GeoServer Configuration](geoserver/latest/README.md)
- [MapStore Configuration](mapstore/latest/README.md)

## Upgrading

```bash
# Update repository cache
helm repo update

# List available chart versions
helm search repo charts/geoserver --versions
helm search repo charts/mapstore --versions

# Upgrade to a specific chart version
helm upgrade geoserver charts/geoserver --version <chart-version> -f my-values.yaml
helm upgrade mapstore charts/mapstore --version <chart-version> -f my-values.yaml

# Example: upgrade to GeoServer chart version 3.0.2
helm upgrade geoserver charts/geoserver --version 3.0.2

# View upgrade history
helm history geoserver

# Rollback to previous version
helm rollback geoserver
```

## Uninstalling

```bash
# Uninstall a release
helm uninstall geoserver
```

## CI/CD Workflows

### Pull Request Validation

When you submit a PR, the [helm-ci.yaml](.github/workflows/helm-ci.yaml) workflow automatically:
1. Lints all charts with `helm lint`
2. Runs unit tests with `helm unittest`
3. Validates Kubernetes manifests with `kubeconform`

### Automated Releases

When changes are merged to main, the [release.yaml](.github/workflows/release.yaml) workflow:
1. Packages charts using `helm package`
2. Publishes to S3 bucket registry (geosolutions-charts)
3. Triggers GitOps deployment updates

## Migrating GeoServer from 2.27.x or 2.28.x to 3.0.x

Starting with GeoServer 3.0.x, the container runs as UID/GID `20000:20000`. When upgrading from 2.27.x or 2.28.x, migrate the ownership of existing GeoServer PVC contents so the new container can read and write them.

- Back up the GeoServer PVCs and database before changing file ownership.
- In [the ownership Job](geoserver/latest/pvc-ownership-20000-job.yaml), verify the PVC claim names. For enabled `gwccache` or `wps` PVCs, uncomment the matching mount and claim.
- Stop the old pod, run the Job to change PVC ownership to `20000:20000`, then delete the completed Job before upgrading.

  ```sh
  kubectl scale statefulset/geoserver -n default --replicas=0
  kubectl wait -n default --for=delete pod/geoserver-0 --timeout=180s
  kubectl apply -n default -f geoserver/latest/pvc-ownership-20000-job.yaml
  kubectl wait -n default --for=condition=complete job/geoserver-pvc-ownership-20000 --timeout=30m
  kubectl delete -n default job/geoserver-pvc-ownership-20000 --cascade=foreground --wait=true
  helm upgrade geoserver charts/geoserver --version 3.0.2 -n default --wait --timeout 3m
  ```
