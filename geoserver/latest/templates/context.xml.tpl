{{- define "geoserver.context.xml" -}}
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
          name="jdbc/postgres" 
          auth="Container" 
          type="javax.sql.DataSource"
          driverClassName="org.postgresql.Driver"
          url="jdbc:postgresql://127.0.0.1:5432/{{ .Values.postgis.env.database }}"
          {{- if .Values.secrets.postgis_external_secret }}
          username="{{ .Values.postgis.env.user }}" 
          password="${POSTGRES_PASSWORD}"
          {{- else }}
          username="{{ .Values.postgis.env.user }}" 
          password="{{ .Values.secrets.postgis_password }}"
          {{- end }}
          initialSize="0"
          minIdle="0" 
          maxTotal="20" 
          maxIdle="5" 
          maxWaitMillis="2000" 
          testWhileIdle="true"
          minEvictableIdleTimeMillis="60000"
          timeBetweenEvictionRunsMillis="30000"
          maxConnLifetimeMillis="600000"
          numTestsPerEvictionRun="5"
          testOnBorrow="false"
          removeAbandonedOnMaintenance="true"
          removeAbandonedTimeout="300"
          logAbandoned="false"
          maxOpenPreparedStatements="20"
          validationQuery="SELECT 1"
     />
</Context>
{{- end -}}
