# Geoportal Server Catalog on Tomcat 9
# Downloads the v3.0.2 WAR from GitHub releases

FROM tomcat:9-jdk11

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download Geoportal Catalog WAR from GitHub releases
# v3.0.2: https://github.com/Esri/geoportal-server-catalog/releases/tag/v3.0.2
ADD https://github.com/Esri/geoportal-server-catalog/releases/download/v3.0.2/geoportal.war \
    /usr/local/tomcat/webapps/geoportal.war

# Tomcat will auto-expand the WAR on startup.
# Config files are mounted as volumes in docker-compose.yml.

EXPOSE 8080
CMD ["catalina.sh", "run"]
