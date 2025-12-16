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
helm repo add charts https://charts.geosolutionsgroup.com

# Update your local chart repository cache
helm repo update

# Search for available charts
helm search repo charts
```

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
helm install mapstore geosolutions/mapstore

# Install with custom values
helm install mapstore geosolutions/mapstore \
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

# Upgrade to latest version
helm upgrade geoserver geosolutions/geoserver

# Upgrade with custom values
helm upgrade geoserver geosolutions/geoserver -f my-values.yaml

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
