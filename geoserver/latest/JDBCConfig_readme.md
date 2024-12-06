# Instructions 

Instructions to install GS with the JDBCConfig family of plugins:

1. Install GS with plugins using our helm chart with following custom_values.yaml:

Adjust the version in URL to match the GS version image that you use:

```yaml
geoserver:
    plugins: "https://build.geoserver.org/geoserver/2.26.x/ext-latest/geoserver-2.26-SNAPSHOT-wps-plugin.zip https://build.geoserver.org/geoserver/2.26.x/ext-latest/geoserver-2.26-SNAPSHOT-wps-cluster-hazelcast-plugin.zip https://build.geoserver.org/geoserver/2.26.x/community-latest/geoserver-2.26-SNAPSHOT-jdbcconfig-plugin.zip https://build.geoserver.org/geoserver/2.26.x/community-latest/geoserver-2.26-SNAPSHOT-jdbcstore-plugin.zip https://build.geoserver.org/geoserver/2.26.x/community-latest/geoserver-2.26-SNAPSHOT-hz-cluster-plugin.zip"
```

```sh
helm install geoserver . --values custom_values.yaml
```

2. Edit the configmap "cm-jdbc-init-import" and ensure correct DB string and credentials:

```sh
kubectl edit configmap/cm-jdbc-init-import
```

3. Also ensure the same credentials are corrected for "cm-jdbc-enabled":

```sh
kubectl edit configmap/cm-jdbc-enabled
```

4. Patch the geoserver statefulset to mount the "cm-jdbc-init-import" configmap and replicaCount is set to 1:

```sh
kubectl patch statefulset geoserver --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/0/name",
    "value": "cm-jdbc-init-import"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/1/name",
    "value": "cm-jdbc-init-import"
  },
  {
    "op": "replace",
    "path": "/spec/replicas",
    "value": 1
  }
]'
```

5. Wait for pods to recreate, reinitialise, let this GeoServer run, monitor the logs and wait for import to complete.

```sh
kubectl logs -f statefulsets/geoserver
```

6. Patch the geoserver statefulset to use the "cm-jdbc-enabled" configmap and to your desired replica count:

```sh
kubectl patch statefulset geoserver --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/0/name",
    "value": "cm-jdbc-enabled"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/1/name",
    "value": "cm-jdbc-enabled"
  },
    {
    "op": "replace",
    "path": "/spec/replicas",
    "value": 2
  }
]'
```

7. Ensure geoserver is restarted