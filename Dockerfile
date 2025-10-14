FROM eclipse-temurin:21.0.8_9-jdk
WORKDIR /app
COPY target/*.jar employees.jar
RUN ls -la /
RUN apt update && apt install -y mc
CMD ["java", "-jar", "employees.jar"]