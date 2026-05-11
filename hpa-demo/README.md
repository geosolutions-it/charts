# EKS HPA Test Reproduce Guide

## Purpose

Use this flow on a fresh EKS cluster to test GeoServer HPA without EBS, StorageClass provisioning, or IAM roles.

This chart is configured for lightweight testing with:

- `persistence.enabled: false`
- pod-local `emptyDir` volumes
- HPA primary signal: `geoserver_requests_per_second` target `500m`
- HPA safety signal: memory target `85%`
- default stress test: `10` workers

This is not a production persistence setup. Pod data is lost when pods are recreated.

## Required Local Tools

```bash
kubectl
helm
aws
```

Make sure `kubectl` points to the new EKS cluster:

```bash
kubectl config current-context
kubectl get nodes
```

Check node memory before installing:

```bash
kubectl top nodes
```

If `kubectl top nodes` fails, install metrics-server in the next step first, then check again.

## 1. Create Namespaces

```bash
kubectl create namespace monitoring
kubectl create namespace geoserver
```

If they already exist, continue.

## 2. Install Metrics Server

This enables the HPA memory signal.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami

helm upgrade --install metrics-server bitnami/metrics-server \
  -n kube-system \
  -f hpa-demo/eks-metrics-server-values.yaml
```

Wait and verify:

```bash
kubectl rollout status deployment/metrics-server -n kube-system
kubectl top nodes
```

## 3. Install Prometheus Stack

This installs Prometheus Operator and the `ServiceMonitor` CRD.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --version 72.5.3 \
  -f hpa-demo/eks-kube-prometheus-stack-values.yaml
```

Wait:

```bash
kubectl rollout status deployment/kube-prometheus-stack-operator -n monitoring
kubectl get pods -n monitoring
```

## 4. Install Prometheus Adapter

This exposes the Prometheus metric as the Kubernetes custom metric used by HPA.

```bash
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
  -n monitoring \
  -f hpa-demo/prometheus-adapter-values.yaml
```

Wait:

```bash
kubectl rollout status deployment/prometheus-adapter -n monitoring
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1
```

It is normal for the custom metrics list to be empty before GeoServer is deployed and scraped.

## 5. Confirm GeoServer Scrape Secret Configuration

The test chart uses the GeoServer admin account for the Prometheus scrape.
The chart creates the Kubernetes scrape secret in the `ServiceMonitor` namespace using the same admin password configured in `values.yaml`.

```yaml
monitoring:
  serviceMonitor:
    basicAuth:
      enabled: true
      createSecret: true
      existingSecret: geoserver-monitoring-basic-auth
secrets:
  admin_password: geoserver
```

## 6. Deploy GeoServer
Update the GeoServer version to `2.28.2` in `geoserver/latest/Chart.yaml`. Then, use the files in `hpa-demo/override` to override the corresponding files in the GeoServer chart

Then deploy:

```bash
helm upgrade --install geoserver geoserver/latest -n geoserver
```

Wait:

```bash
kubectl rollout status statefulset/geoserver -n geoserver
kubectl get pods -n geoserver
kubectl get pvc -n geoserver
```

Expected for this simple test mode:

```text
geoserver-0   1/1   Running
No resources found in geoserver namespace.
```

## 7. Confirm Prometheus Scrape And HPA Metrics

Give Prometheus one scrape interval, then check:

```bash
kubectl get hpa -n geoserver geoserver
kubectl top pods -n geoserver
```

Expected HPA shape:

```text
TARGETS
<request-rate>/500m, memory: <memory-percent>/85%
```

If request rate is `<unknown>`, wait one or two scrape intervals and check Prometheus target health:

```bash
kubectl run prom-target-check -n monitoring --rm -i --restart=Never \
  --image=curlimages/curl:8.11.1 -- \
  sh -c 'curl -s "http://kube-prometheus-stack-prometheus.monitoring.svc:9090/api/v1/targets?state=active" | tr "," "\n" | grep -E "scrapeUrl|lastError|health|job\":\"geoserver|pod\":\"geoserver" | head -30'
```

GeoServer target should show:

```text
"lastError":""
"health":"up"
```

## 8. Run Default HPA Stress Test

```bash
bash hpa-demo/scripts/stress-hpa.sh
```

Defaults:

- `WORKERS=10`
- `DURATION_SECONDS=240`
- HPA request-rate target `500m`

Expected result on small EKS test nodes:

- HPA remains at `1` replica if request rate stays below `500m`
- memory remains below `85%`
- this confirms HPA is reading both metrics, but load is not high enough to scale

Example observed result:

```text
geoserver_requests_per_second: 199m / 500m
memory: 69% / 85%
StatefulSet pods: 1 current / 1 desired
```

Observe the test live while it runs:

```bash
kubectl get hpa -n geoserver geoserver -w
kubectl get pods -n geoserver -w
kubectl top pods -n geoserver
kubectl describe hpa -n geoserver geoserver
```

## 9. Optional Scale-Up Demonstration

The default `10` workers may not exceed the `500m` target. To force a clearer scale-up test:

```bash
WORKERS=40 \
DURATION_SECONDS=300 \
./geoserver/latest/tests/stress-hpa.sh
```

Watch in another terminal:

```bash
kubectl get hpa -n geoserver geoserver -w
kubectl get pods -n geoserver -w
kubectl top nodes
```

After load stops, scale-down is delayed by the configured `120s` stabilization window.

## Cleanup

```bash
helm uninstall geoserver -n geoserver
helm uninstall prometheus-adapter -n monitoring
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall metrics-server -n kube-system

kubectl delete namespace geoserver
kubectl delete namespace monitoring
```
