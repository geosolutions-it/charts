# GeoServer Helm Chart

## Helm Chart Installation

1) Clone the helm chart repo

```bash
git clone https://github.com/geosolutions-it/charts.git
```

2) Within the root of the helm chart, create a custom `values.yaml` file

```bash
cp geoserver/v0.1.0/values.yaml geoserver/v0.1.0/custom-values.yaml
```

3) Edit sample `context.xml` to add as many JNDI datasources are needed. The sample `context.xml` contains by default the JNDI datasource for the embedded postgis service that can be enabled in `values.yaml`. Example:

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

Concerning the security context of pod and pv(s), it is recommended not to comment out this section, because the docker image runs natively as non root, althogh the id or gid of `1000` can be changed to anything else and they can be differnt values, in case the infrastructure requires different ID/GID mapping:

```yml
podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

Once the `custom-values.yaml` is ready and suits the configuration needs, the helm chart can be deployed like this:

```bash
cd geoserver/v0.1.0
helm3 install geoserver . --values ./custom-values.yaml
```

Once configured you will be promped with the geoserver final URL with the customized hostname (dns records are not handled by the chart) served by the k8s ingress.

## Notes on GeoServer configuration

### Admin password change

You can put a custom password at installation time, so it is not the default which is `notgeoserver` and it is *different* from war's default that is `geoserver`.
If you want to change the password you can do it via [REST API](https://docs.geoserver.org/stable/en/user/rest/api/selfadmin.html) or with the GeoServer UI:

- Click on the left, under Security section, "Users,Groups, and Roles"
- Click on Users/Groups tab, then click on admin user
- Edit the password and save.

### Specific configuration options for GeoServer

The default directory structure, possibility to add plugins to the GeoServer war file, enable/disable [JAI extension](https://docs.geoserver.org/master/en/user/configuration/image_processing/index.html), enable or disable [CSRF (Cross-Site Request Forgery)](https://docs.geoserver.org/stable/en/user/security/webadmin/csrf.html),configure tomcat's `Xmx` maximum memory allocation pool and `Xms` or tomcat's initial memory allocation pool.

```yml
geoserver:
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
```

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