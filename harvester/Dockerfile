# Geoportal Server Harvester on Tomcat 9
# Downloads the v3.0.0 WAR from GitHub releases

FROM tomcat:9-jdk11

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download and pre-expand the WAR so volume mounts can target specific files
ADD https://github.com/Esri/geoportal-server-harvester/releases/download/v3.0.0/geoportal-harvester-war-3.0.0.war \
    /tmp/harvester.war
RUN mkdir -p /usr/local/tomcat/webapps/harvester && \
    cd /usr/local/tomcat/webapps/harvester && \
    jar xf /tmp/harvester.war && \
    rm /tmp/harvester.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
