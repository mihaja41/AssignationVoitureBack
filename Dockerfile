FROM tomcat:10.1-jdk21

# Nettoyer les apps par défaut
RUN rm -rf /usr/local/tomcat/webapps/*

# Copier ton WAR
COPY build/project1.war /usr/local/tomcat/webapps/ROOT.war

# Railway utilise PORT
ENV PORT=8080
EXPOSE 8080

CMD ["catalina.sh", "run"]
