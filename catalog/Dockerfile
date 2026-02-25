# Geoportal Server Catalog on Tomcat 9
# Downloads the v3.0.2 WAR from GitHub releases

FROM tomcat:9-jdk11

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download and pre-expand the WAR so volume mounts can target specific files
ADD https://github.com/Esri/geoportal-server-catalog/releases/download/v3.0.2/geoportal_3.0.2.war \
    /tmp/geoportal.war
RUN mkdir -p /usr/local/tomcat/webapps/geoportal && \
    cd /usr/local/tomcat/webapps/geoportal && \
    jar xf /tmp/geoportal.war && \
    rm /tmp/geoportal.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
