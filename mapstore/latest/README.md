# Mapstore Helm Chart

## Helm Chart Installation

### Chart deployment

1) Clone the helm chart repo

```bash
git clone https://github.com/geosolutions-it/charts.git
cd charts/mapstore/latest
```

2) Within the root of the helm chart, create a custom `values.yaml` file

```bash
cp ./values.yaml ./custom-values.yaml
```

3) Once the `custom-values.yaml` is ready and suits the configuration needs, the helm chart can be deployed like this:

```bash
helm install mapstore . --values ./custom-values.yaml
```

Note: For the K8s Ingress to work and Mapstore be directly exposed on a public IP address, make sure you have a working Ingress Controller configured in your the cluster.

```bash
kubectl get ingress
```
Should give you the IP address at which you can contact Mapstore as shown below.

![image](https://github.com/david7378/charts/assets/88064044/f5c58247-7622-412b-95a0-16bbcd7c3b4e)


### Testing

For a quick test create a Port Forward to the Mapstore Pod

1) Create a [Port Forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) to mapstore. For instance:
   
```bash
kubectl port-forward mapstore-0 8080:8080
```


2) Open your browser and navigate to http://localhost:8080/mapstore. You can see the User interface of Mapstore same like below screenshot.
- Use the default credentials (admin / admin) to login and start creating your maps!

![image](https://github.com/david7378/charts/assets/88064044/1ad0dd3e-cf75-423c-83a2-cf17ee41583b)

## Notes on specific clouds

### AWS

In case of deploying this chart on EKS the mapstore service will be most likely exposed with AWS's ingress of kind alb.
When using `alb` as an ingress backend, the service must be exposed as `NodePort` and not `ClusterIP`, which is the more generic default.
So this piece in `values.yaml` becomes from this:
```yml
service:
  type: ClusterIP
  port: 80
```

To this:
```yml
service:
  type: NodePort
  port: 80
```

Reference: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
