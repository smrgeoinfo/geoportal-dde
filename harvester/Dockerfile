# Geoportal Server Harvester on Tomcat 9
# Downloads the v3.0.0 WAR from GitHub releases
# Includes custom CDIF Sitemap connector JAR

FROM tomcat:9-jdk11

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download Geoportal Harvester WAR from GitHub releases
# v3.0.0: https://github.com/Esri/geoportal-server-harvester/releases/tag/v3.0.0
ADD https://github.com/Esri/geoportal-server-harvester/releases/download/v3.0.0/harvester.war \
    /usr/local/tomcat/webapps/harvester.war

# The custom CDIF connector JAR will be added after building the Maven module.
# For now, it can be mounted or copied in:
# COPY cdif-connector/target/geoportal-harvester-cdif-sitemap-1.0.0.jar \
#      /usr/local/tomcat/webapps/harvester/WEB-INF/lib/

EXPOSE 8080
CMD ["catalina.sh", "run"]
