FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY target/assignation-voiture.war app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
