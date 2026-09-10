# GeoServer Autoscaling based on requests per second and JVM heap

This folder contains values to enable RPS and JVM heap autoscaling on an existing GeoServer Helm release.

Run the commands from this folder, using the updated parent chart (`../..`). The examples use:

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

Edit the [autoscaling configuration](./values.yaml) and [adapter values](./prometheus-adapter-values.yaml) directly. Adjust the release/namespace, Prometheus URL, ServiceMonitor namespace/labels, authentication, and Adapter metric as needed.

```bash
helm upgrade geoserver ../.. -n geoserver --reset-then-reuse-values \
  -f values.yaml --set replicaCount=2 --wait --timeout 8m
```

After the rollout, send WMS/WFS requests to each serving pod. In Prometheus, confirm both jobs have `up == 1`, `requests_total_seconds_count` is present, and each pod has `java_lang_Memory_HeapMemoryUsage_used` and a positive `java_lang_Memory_HeapMemoryUsage_max`.

## 3. Install or update Adapter

Use the existing Adapter release if present. Merge its current rules/settings into the supplied file first (`helm get values prometheus-adapter -n monitoring`).

```bash
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
  -n monitoring --create-namespace --version 4.14.1 --reuse-values \
  -f prometheus-adapter-values.yaml --wait --timeout 3m
```

Verify the custom metrics API:

```bash
kubectl get --raw '/apis/custom.metrics.k8s.io/v1beta1/namespaces/geoserver/pods/*/geoserver_requests_total_per_second'
kubectl get --raw '/apis/custom.metrics.k8s.io/v1beta1/namespaces/geoserver/pods/*/geoserver_heap_pressure_percent'
```

Continue when both APIs return one value per serving pod. Zero heap pressure is valid below the baseline. Missing/invalid heap data can block downscale while valid RPS can still request scale-up. See [HPA behavior](https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/).

## 4. Enable autoscaling

```bash
helm upgrade geoserver ../.. -n geoserver --reuse-values \
  -f values.yaml --set autoscaling.enabled=true --wait --timeout 8m
kubectl get hpa -n geoserver
```

## 5. Disable or re-enable

Disable HPA and choose a fixed count:

```bash
helm upgrade geoserver ../.. -n geoserver --reuse-values \
  --set autoscaling.enabled=false --set replicaCount=2 --wait --timeout 8m
kubectl get hpa,statefulset -n geoserver
```

Helm removes the HPA and sets the chosen replica count. Monitoring and Adapter remain available. Run step 4 to re-enable. To remove the exporter too, add `--set jvmMetrics.enabled=false` to the disable command; this rolls out GeoServer again.

To return to RPS-only scaling, run from this folder:

```bash
helm upgrade geoserver ../.. -n geoserver --reuse-values \
  -f ../rps/values.yaml \
  --set autoscaling.enabled=true --wait --timeout 8m
```

Add `--set jvmMetrics.enabled=false` if heap monitoring is no longer needed.

## 6. Grafana queries

An example dashboard, [grafana-dashboard.json](./grafana-dashboard.json), is available for reference.

Some example queries in the dashboard:

- **Heap used — raw and smoothed:** shows current heap usage and its validated 2-minute average as percentages of the JVM maximum.
- **Heap pressure used by HPA:** shows valid smoothed heap usage above the baseline; `80% − 50% = 30` pressure points at the default target.
- **Completed request rate per pod:** shows the healthy-pod RPS values supplied to HPA by Adapter.
- **Total completed request rate:** sums those pod rates to show total monitored traffic from healthy scrapes.
- **Ready / desired replicas:** compares pods ready to serve with the requested replica count.

