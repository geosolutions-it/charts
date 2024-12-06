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

2. Edit the configmap "cm-jdbcconfig-init-import" and ensure correct DB string and credentials:

```sh
kubectl edit configmap/cm-jdbcconfig-init-import
```

3. Also ensure the same credentials are corrected for "cm-jdbcconfig-enabled":

```sh
kubectl edit configmap/cm-jdbcconfig-enabled
```

4. Patch the geoserver statefulset to mount the "cm-jdbcconfig-init-import" configmap:

```sh
kubectl patch statefulset geoserver --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/0",
    "value": {
      "name": "cm-jdbcconfig-init-import",
      "mountPath": "/var/geoserver/datadir/jdbcconfig/jdbcconfig.properties",
      "subPath": "jdbccfg.properties"
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/1",
    "value": {
      "name": "cm-jdbcconfig-init-import",
      "mountPath": "/var/geoserver/datadir/jdbcstore/jdbcstore.properties",
      "subPath": "jdbccfg.properties"
    }
  }
]'
```

5. Let this GeoServer run, monitor the logs and wait for import to complete.

```sh
kubectl logs -f statefulsets/geoserver
```

6. Patch the geoserver statefulset to use the "cm-jdbcconfig-enabled" configmap now:

```sh
kubectl patch statefulset geoserver --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/0/name",
    "value": "cm-jdbcconfig-enabled"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/volumeMounts/1/name",
    "value": "cm-jdbcconfig-enabled"
  }
]'
```

7. Ensure geoserver is restarted