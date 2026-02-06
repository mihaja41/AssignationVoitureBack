FROM tomcat:10.1-jdk21-temurin

WORKDIR /usr/local/tomcat/webapps

COPY targets/assignation-voiture.war ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
