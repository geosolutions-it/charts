# GeoServer Helm Chart

## Helm Chart Installation

### Admin password change

You can put a custom password at installation time in `values.yaml`, so it is not the default which is `notgeoserver` and it is *different* from war's default that is `geoserver`.
If you want to change the password you can do it via [REST API](https://docs.geoserver.org/stable/en/user/rest/api/selfadmin.html) or with the GeoServer UI:

- Click on the left, under Security section, "Users,Groups, and Roles"
- Click on Users/Groups tab, then click on admin user
- Edit the password and save.


### Chart deployment

1) Clone the helm chart repo

```bash
git clone https://github.com/geosolutions-it/charts.git
cd charts/geoserver/latest
```

2) Within the root of the helm chart, create a custom `values.yaml` file

```bash
cp ./values.yaml ./custom-values.yaml
```


Once the `custom-values.yaml` is ready and suits the configuration needs, the helm chart can be deployed like this:

```bash
helm3 install geoserver . --values ./custom-values.yaml
```

Once configured you will be promped with the geoserver final URL with the customized hostname (dns records are not handled by the chart) served by the k8s ingress.

Note: For the K8s Ingress to work and GeoServer be directly exposed on a public IP address, make sure you have a working Ingress Controller configured in your the cluster.

```bash
kubectl get ingress
```
Should give you the IP address at which you can contact GeoServer as shown below.

![image](https://user-images.githubusercontent.com/5264230/220570461-76b451ac-7b50-4320-a182-8a765ae2fbef.png)


### Testing

For a quick test create a Port Forward to the GeoServer Pod

1) Create a [Port Forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) to geoserver. For instance:
   
```bash
kubectl port-forward geoserver-0 8080:8080
```


2) Open your browser and navigate to http://localhost:8080/geoserver. You can see the User interface of geoserver same like below screenshot. 


![Screenshot_20230217_024956](https://user-images.githubusercontent.com/94710364/219696756-c4404c25-6442-41f2-bcc7-7893a32f6123.png)


## Notes on GeoServer configuration

### Specific configuration options for GeoServer

- The default directory structure is fully configurable.
- There is possibility to add plugins to the GeoServer war file
- Possibility to enable/disable [JAI extension](https://docs.geoserver.org/master/en/user/configuration/image_processing/index.html)
- Possibility to enable or disable [CSRF (Cross-Site Request Forgery)](https://docs.geoserver.org/stable/en/user/security/webadmin/csrf.html)
- configure tomcat's `Xmx`  maximum Java heap size
- configure tomcat's `Xms` initial Java heap size.
- Possibility to populate the `environment.properties` file with custom env vars, to have them available in the GeoServer config

Example:
```yml
geoserver:
  chown_datadir: true

  # space separated list of plugin URLs (see also this possibility below to format such string)
  # plugins: "https://sourceforge.net/projects/geoserver/files/GeoServer/2.20.4/extensions/geoserver-2.20.4-monitor-plugin.zip \
  #   https://sourceforge.net/projects/geoserver/files/GeoServer/2.20.4/extensions/geoserver-2.20.4-control-flow-plugin.zip"
  # to enable audit logging once the pod is deployed go inside the geoserver pod and configure it in the datadir according to doc:
  # https://docs.geoserver.org/latest/en/user/extensions/monitoring/audit.html
  plugins: ""
  geoserver_log_location: "/var/geoserver/logs/$(POD_HOSTNAME).log"
  geoserver_audit_path: "/var/geoserver/audits"
  geoserver_heap_dump_dir: "/var/geoserver/memory_dumps"
  geoserver_data_dir: "/var/geoserver/datadir"
  geoserver_cache_data_dir: "$(GEOSERVER_DATA_DIR)/gwc_cache_dir"
  geoserver_cache_config_dir: "$(GEOSERVER_DATA_DIR)/gwc"
  geoserver_netcdf_data_dir: "/var/geoserver/netcdf_data_dir"
  geoserver_grib_cache_dir: "/var/geoserver/grib_cache_dir"
  geoserver_csrf_disabled: "true"
  geoserver_jai_ext_enabled: "true"
  geoserver_java_mem_xms: "4G"
  geoserver_java_mem_xmx: "4G"

  geoserver_extra_opts: >

  env_properties: |
    EXAMPLE_DB_NAME=geoserver
    EXAMPLE_DB_HOST=localhost
    EXAMPLE_DB_USER=geoserver
    EXAMPLE_DB_PASS=geoserver

  context_xml: |

```

#### Description:
- `context_xml`: pupulate the secret for the Tomcat `context.xml` file.
- `chown_datadir`: toggle running `chown` to the `tomcat` UID/GID on the GeoServer data\_dir.  
  Disabling this might be desired when particular storage drivers requires to not change the ownership.
- `geoserver_extra_opts`: JVM options that will be appended to the default ones.

## Notes on specific clouds

### AWS

In case of deploying this chart on EKS the geoserver service will be most likely exposed with AWS's ingress of kind alb.
When using `alb` as an ingress backend, the service must be exposed as `NodePort` and not `ClusterIP`, which is the more generic default.
So this piece in `values.yaml` becomes from this:
```yml
service:
  type: ClusterIP
  port: 80
```

This:
```yml
service:
  type: NodePort
  port: 80
```

Reference: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

### Optional JNDI configuration for PostGIS

In case embedded PostGIS service is enable or per-existing database server is to be used, there is the possibility to configure automatically 
tomcat JNDI connections at deployment time.
Edit sample `context.xml` to add as many JNDI datasources are needed. The sample `context.xml` contains by default the JNDI datasource for the embedded postgis service that can be enabled in `values.yaml`. Example:

```xml
<Context>

    <!-- Default set of monitored resources -->
    <WatchedResource>WEB-INF/web.xml</WatchedResource>

    <!-- Uncomment this to disable session persistence across Tomcat restarts -->
    <!--
    <Manager pathname="" />
    -->

    <!-- Uncomment this to enable Comet connection tacking (provides events
         on session expiration as well as webapp lifecycle) -->
    <!--
    <Valve className="org.apache.catalina.valves.CometConnectionManagerValve" />
    -->

    <Resource
     name="jdbc/postgres" auth="Container" type="javax.sql.DataSource"
     driverClassName="org.postgresql.Driver"
     url="jdbc:postgresql://127.0.0.1:5432/geoserver"
     username="geoserver" password="geoserver"
     initialSize="0" maxActive="20" maxIdle="5" maxWait="2000" minIdle="0"
     timeBetweenEvictionRunsMillis="30000"
     minEvictableIdleTimeMillis="60000"
     validationQuery="SELECT 1"
     maxAge="600000"
     rollbackOnReturn="true"
     />
</Context>
```
