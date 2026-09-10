# GeoServer Autoscaling based on requests per second

This folder contains additional values to enable autoscaling on an existing GeoServer Helm release.

Run the commands from this folder. The examples use:

- GeoServer release/namespace: `geoserver`
- Prometheus and Adapter namespace: `monitoring`
- Prometheus release: `kube-prometheus-stack`
- Adapter release: `prometheus-adapter`

## 1. Install prerequisites

Install these components:

- **Monitor and monitor-micrometer extensions** in GeoServer, matching its version. See the [extension installation guide](https://docs.geoserver.org/latest/en/user/community/monitor-micrometer/installation/).
- **Prometheus and Prometheus Operator**, including the ServiceMonitor CRD, to collect request metrics.
- **Prometheus Adapter**, installed in step 3, to expose those metrics to HPA.


Register the Helm repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm list -A
```

If Prometheus/Operator already exist, reuse them and continue to step 2. Otherwise, install the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --wait --timeout 10m
kubectl get crd servicemonitors.monitoring.coreos.com
kubectl get prometheus,pods -n monitoring
```

## 2. Configure GeoServer monitoring

Edit the [autoscaling configuration](./geoserver-rps-values.yaml) and [adapter values](./prometheus-adapter-values.yaml) directly. Adjust the release/namespace, Prometheus URL, ServiceMonitor namespace/labels, authentication, and Adapter metric as needed.

```bash
helm upgrade geoserver .. -n geoserver --reuse-values \
  -f geoserver-rps-values.yaml --wait --timeout 5m
```

This applies monitor settings and creates the ServiceMonitor. Confirm Prometheus reports `up == 1` and `requests_total_seconds_count` for each pod. The metrics endpoint is `/geoserver/rest/monitor/requests/metrics`.

## 3. Install or update Adapter

Use the existing Adapter release if present. Before updating it, merge its current rules/settings into `prometheus-adapter-values.yaml` (`helm get values prometheus-adapter -n monitoring`).

```bash
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
  -n monitoring --create-namespace --version 4.14.1 --reuse-values \
  -f prometheus-adapter-values.yaml --wait --timeout 3m
```

Verify the custom metrics API:

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

Helm removes the HPA and sets the chosen replica count. Run step 4 again to re-enable autoscaling.
