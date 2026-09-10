# GeoServer Autoscaling based on request-per-second

This folder contains additional values to enable autoscaling on an existing GeoServer Helm release.

Some example values for testing:

- GeoServer release/namespace: `geoserver`
- Prometheus and Adapter namespace: `monitoring`
- Adapter release: `prometheus-adapter`

## 1. Edit the configuration

Edit the [autoscaling configuration](./geoserver-rps-values.yaml) and [adapter values](./prometheus-adapter-values.yaml) YAML files directly. GeoServer needs the monitor-micrometer extension, and Prometheus Operator must be installed for the ServiceMonitor.


## 2. Prepare monitoring stack


```bash
helm upgrade geoserver .. -n geoserver --reuse-values \
  -f geoserver-rps-values.yaml --wait --timeout 5m
```

This will apply monitor settings and creates the ServiceMonitor. Allow the GeoServer rollout to finish, then confirm Prometheus reports `up == 1` and `requests_total_seconds_count` for every serving pod. The metrics endpoint is `/geoserver/rest/monitor/requests/metrics`; these values use 30-second scrapes.

## 3. Install or update Adapter

Use the existing Adapter release if present. Before updating it, merge its current rules/settings into `prometheus-adapter-values.yaml` (`helm get values prometheus-adapter -n monitoring`).

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
  -n monitoring --create-namespace --version 4.14.1 --reuse-values \
  -f prometheus-adapter-values.yaml --wait --timeout 3m
```

Verify the scrape is working:

```bash
kubectl get --raw '/apis/custom.metrics.k8s.io/v1beta1/namespaces/geoserver/pods/*/geoserver_requests_total_per_second'
```

Continue when the API returns one value per serving pod.

## 4. Enable autoscaling

```bash
helm upgrade geoserver .. -n geoserver --reuse-values \
  -f geoserver-rps-values.yaml --set autoscaling.enabled=true --wait --timeout 5m
kubectl get hpa -n geoserver
```

## 5. Disable or re-enable

Disable autoscaling and choose a fixed replica count (`2` below is an example):

```bash
helm upgrade geoserver .. -n geoserver --reuse-values \
  --set autoscaling.enabled=false --set replicaCount=2 --wait --timeout 5m
kubectl get hpa,statefulset -n geoserver
```

Helm removes the HPA and sets the chosen replica count. Monitoring and Adapter remain available. Run step 4 again to re-enable autoscaling.
