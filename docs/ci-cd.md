# CI/CD implementálása Java projekten szabadon választható eszközökkel - gyakorlati feladatok

## Telepítendő szoftverek

- Git
- JDK 21
- Visual Studio Code
- Docker Desktop
- Windows Subsystem for Linux 2 + Ubuntu

## Szolgáltatások

- GitHub regisztráció (ingyenes)
- Docker Hub regisztráció (ingyenes)

## Maven build eszköz - gyakorlat

```shell
git clone https://github.com/Training360/javax-cip-public
xcopy /e /i javax-cip-public\employees employees
cd employees
code .
```

- Könyvtárszerkezet bemutatása
- `pom.xml` bemutatása

## Maven futtatás - gyakorlat

```shell
mvnw package
```

- `target`, `classes` könyvtár

```shell
mvnw clean
mvnw clean package
```

- Fázisok bemutatása

```shell
mvnw spring-boot:run
```

- Webes felület: `http://localhost:8080`

## Maven függőségek - gyakorlat

- Függőségek

```shell
mvnw help:effective-pom > effective-pom.log
```

- Central repo: https://repo1.maven.org/maven2
- Local repository

```shell
mvnw install
```

- Függőségek letöltése

```shell
mvnw dependency:tree > tree.log
```

- Függőség és plugin verziószámok

```shell
mvnw versions:display-dependency-updates > updates.log
```

## Maven unit tesztek futtatása - gyakorlat

```shell
mvnw test
```

- `target/surefire-reports`

## Maven tesztlefedettség - gyakorlat

Újabb Java esetén újabb Jacoco verziót kell használni!
Pl. a 0.8.11 támogatja hivatalosan a Java 21-et.

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <executions>
        <execution>
            <id>jacoco-initialize</id>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>jacoco-site</id>
            <phase>package</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

```shell
mvnw package
```

## Maven csomagolás - gyakorlat

```shell
mvnw package
jar -tf .\target\employees-1.0.0.jar
```

```shell
cd target
java -jar employees-1.0.0.jar
```

## Bevezetés a Docker használatába - gyakorlat

```shell
docker version
docker run hello-world
docker run -p 80:80 -d --name my-nginx nginx
docker ps
docker stop 517e15770697
docker ps -a
docker start my-nginx
docker logs -f my-nginx
docker stop my-nginx
docker rm my-nginx
```

Használható az azonosító első egyértelmű megkülönböztetést lehetővé tevő karakterei is

```shell
docker images
docker rmi nginx
```

## Nexus repo manager - gyakorlat

```shell
docker run --name nexus -d -p 8091:8081 -p 8092:8082 sonatype/nexus3
```

```shell
docker exec -it nexus cat /nexus-data/admin.password
```

## Nexus repo manager Maven proxyként - gyakorlat

```shell
mvnw dependency:purge-local-repository
```

`~/.m2/settings.xml` fájlban

```xml
<settings>
    <mirrors>
        <mirror>
            <id>nexus</id>
            <mirrorOf>*</mirrorOf>
            <url>http://localhost:8091/repository/maven-public/</url>
        </mirror>
    </mirrors>
</settings>
```

## Deploy Mavennel Nexus repoba - gyakorlat

```xml
<distributionManagement>
    <repository>
        <id>nexus-releases</id>
        <url>http://localhost:8091/repository/maven-releases/</url>
    </repository>
</distributionManagement>
```

C:\Users\iviczian\.m2

`~/.m2/settings.xml` fájlban a `settings` tagen belül

```xml
<servers>
   <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>admin</password>
   </server>
</servers>
```

```shell
mvnw deploy
```

## Integrációs tesztek Mavennel in-memory adatbázissal - gyakorlat

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>2.22.2</version>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

```shell
mvnw verify
```

## Integrációs tesztek Mavennel valós adatbázissal - gyakorlat

> Itt egyszerűbb megoldás, hogy közvetlenül operációs
> rendszer környezeti változóból konfiguráljuk a Spring-et,
> azaz Windows esetén pl. `SET SPRING_DATASOURCE_URL=jdbc:mariadb://localhost/employees`

```shell
docker run -d -e MARIADB_DATABASE=employees -e MARIADB_USER=employees -e MARIADB_PASSWORD=employees -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=yes -p 3306:3306 --name employees-it-mariadb mariadb
```

```xml
<properties>
    <test.datasource.url>jdbc:h2:mem:db;DB_CLOSE_DELAY=-1</test.datasource.url>
    <test.datasource.username>sa</test.datasource.username>
    <test.datasource.password>sa</test.datasource.password>
</properties>

<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>2.22.2</version>
    <configuration>
        <systemPropertyVariables>
            <spring.datasource.url>${test.datasource.url}</spring.datasource.url>
            <spring.datasource.username>${test.datasource.username}</spring.datasource.username>
            <spring.datasource.password>${test.datasource.password}</spring.datasource.password>
        </systemPropertyVariables>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

```shell
.\mvnw clean "-Dtest.datasource.url=jdbc:mariadb://localhost/employees" "-Dtest.datasource.username=employees" "-Dtest.datasource.password=employees" verify
```

## Csomagolás Docker Image-be Dockerfile használatával Maven projekt esetén - gyakorlat

`Dockerfile` fájl tartalma:

```dockerfile
FROM eclipse-temurin:17
WORKDIR /app
COPY target/employees-1.0.0.jar employees.jar
CMD ["java", "-jar", "employees.jar"]
```

```shell
docker build -t employees .
```

```shell
docker run -d --name employees -p 8080:8080 employees
docker logs -f employees
```

## Csomagolás Docker Image-be Dockerfile használatával Gradle projekt esetén - gyakorlat

`Dockerfile` fájl tartalma:

```dockerfile
FROM eclipse-temurin:17
WORKDIR /app
COPY build/libs/employees-gradle-1.0.0.jar employees.jar
CMD ["java", "-jar", "employees.jar"]
```

```shell
docker build -t employees .
```

```shell
docker run -d --name employees-gradle -p 8081:8080 employees-gradle
docker logs -f employees-gradle
```

## Docker layers Maven esetén

> Depracated, Spring Boot 3.3 óta más parancsokat kell használni, lsd. később.

```shell
mkdir tmp
cd tmp
java -Djarmode=layertools -jar ..\target\employees-1.0.0.jar extract
```

`Dockerfile.layered` tartalma:

```dockerfile
FROM eclipse-temurin:17 as builder
WORKDIR /app
COPY target/employees-1.0.0.jar employees.jar
RUN java -Djarmode=layertools -jar employees.jar extract

FROM eclipse-temurin:17
WORKDIR /app
COPY --from=builder app/dependencies/ ./
COPY --from=builder app/spring-boot-loader/ ./
COPY --from=builder app/snapshot-dependencies/ ./
COPY --from=builder app/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

```shell
docker build --file Dockerfile.layered  -t employees .
```

- `EmployeesWebController` módosítása

```java
log.debug("List employees");
```

```shell
mvnw clean package
```

## Docker layers Maven esetén Spring Boot 3.3 óta

```dockerfile
FROM eclipse-temurin:17 AS builder
WORKDIR /app
COPY target/employees-1.0.0.jar employees.jar
RUN java -Djarmode=tools -jar employees.jar extract --layers --destination extracted

FROM eclipse-temurin:17
WORKDIR /app
COPY --from=builder /app/extracted/dependencies/ ./
COPY --from=builder /app/extracted/spring-boot-loader/ ./
COPY --from=builder /app/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/extracted/application/ ./
CMD ["java", "-jar", "employees.jar"]
```

## Docker repository létrehozása Nexus-ban

- Create Docker hosted repository (port `8082`)
- Adminisztrációs felületen: _Security / Realms_ tabon: _Docker Bearer Token Realm_ hozzáadása

## Docker image deploy Nexus-ba Mavennel - gyakorlat

```shell
docker tag employees:1.0.0 localhost:8092/employees
docker login localhost:8092
docker push localhost:8092/employees
```

## Docker compose használata - gyakorlat

> A `wait-for-it.sh` használatát kerüljük, helyette healtcheck, lsd. később!

```shell
curl https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o wait-for-it.sh
```

```yaml
version: "3"

services:
  mariadb:
    image: mariadb
    expose:
      - 3306
    environment:
      MARIADB_DATABASE: employees
      MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: "yes" # aposztrófok nélkül boolean true-ként értelmezi
      MARIADB_USER: employees
      MARIADB_PASSWORD: employees
    ports:
      - 3306:3306

  employees-app:
    image: employees:1.0.0
    depends_on:
      - mariadb
    expose:
      - 8080
    environment:
      SPRING_DATASOURCE_URL: "jdbc:mariadb://mariadb:3306/employees"
      SPRING_DATASOURCE_USERNAME: employees
      SPRING_DATASOURCE_PASSWORD: employees
    volumes:
      - ./wait:/opt/wait
    entrypoint:
      [
        "/opt/wait/wait-for-it.sh",
        "-t",
        "120",
        "mariadb:3306",
        "--",
        "/cnb/process/web",
      ]
    ports:
      - 8080:8080
```

A `wait-for-it.sh` nélkül:

```yaml
version: "3"

services:
  mariadb:
    image: mariadb
    expose:
      - 3306
    environment:
      MARIADB_DATABASE: employees
      MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: "yes" # aposztrófok nélkül boolean true-ként értelmezi
      MARIADB_USER: employees
      MARIADB_PASSWORD: employees
    ports:
      - 3306:3306
    healthcheck:
      test:
        [
          "CMD",
          "healthcheck.sh",
          "--su-mysql",
          "--connect",
          "--innodb_initialized",
        ]
      interval: 5s
      retries: 3
      timeout: 20s

  employees-app:
    image: employees:1.0.0
    depends_on:
      mariadb:
        condition: service_healthy
    expose:
      - 8080
    environment:
      SPRING_DATASOURCE_URL: "jdbc:mariadb://mariadb:3306/employees"
      SPRING_DATASOURCE_USERNAME: employees
      SPRING_DATASOURCE_PASSWORD: employees
    ports:
      - 8080:8080
```

```shell
docker compose up -d
docker compose logs -f
docker exec -it employees-mariadb-1 mariadb employees
```

```sql
select * from employees;
```

- DBeaver

```shell
docker compose down
```

## E2E tesztelés Selenium WebDriverrel - gyakorlat

> Kerüljük a `wait-for-it.sh` használatát, lásd később!

```shell
xcopy /e /i .\javax-cip-public\employees-selenium employees-selenium
```

```dockerfile
FROM eclipse-temurin:17
WORKDIR /tests
COPY . .
RUN chmod +x mvnw
ENTRYPOINT ["./mvnw", "test"]
```

Optimalizáció:

```dockerfile
FROM eclipse-temurin:17
WORKDIR /tests
COPY pom.xml pom.xml
COPY mvnw mvnw
COPY .mvn .mvn
RUN chmod +x mvnw
RUN ./mvnw test
COPY src src
RUN ./mvnw test-compile
ENTRYPOINT ["./mvnw", "test"]
```

`docker-compose.yaml` fájl

```yaml
version: "3"
services:
  selenium-hub:
    image: selenium/hub
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"

  chrome:
    image: selenium/node-chrome
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - selenium-hub
    environment:
      SE_EVENT_BUS_HOST: selenium-hub
      SE_EVENT_BUS_PUBLISH_PORT: 4442
      SE_EVENT_BUS_SUBSCRIBE_PORT: 4443
    expose:
      - "5900"
    privileged: true

  chrome-video:
    image: selenium/video:ffmpeg-4.3.1-20210527
    volumes:
      - ./videos:/videos
    depends_on:
      - chrome
    environment:
      DISPLAY_CONTAINER_NAME: chrome
      FILE_NAME: chrome-video.mp4

  mariadb:
    image: mariadb
    expose:
      - 3306
    environment:
      MARIADB_DATABASE: employees
      MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: "yes"
      MARIADB_USER: employees
      MARIADB_PASSWORD: employees

  employees-app:
    image: employees:1.0.0
    expose:
      - 8080
    volumes:
      - ./wait:/opt/wait
    depends_on:
      - mariadb
    environment:
      SPRING_DATASOURCE_URL: "jdbc:mariadb://mariadb:3306/employees"
      SPRING_DATASOURCE_USERNAME: employees
      SPRING_DATASOURCE_PASSWORD: employees
    entrypoint:
      [
        "/opt/wait/wait-for-it.sh",
        "-t",
        "120",
        "mariadb:3306",
        "--",
        "/cnb/process/web",
      ]

  employees-selenium:
    build: .
    image: employees-selenium
    volumes:
      - ./surefire-reports:/tests/target/surefire-reports
      - ./wait:/opt/wait
    depends_on:
      - employees-app
    environment:
      SELENIUM_DRIVER: RemoteWebDriver
      SELENIUM_HUB_URL: http://selenium-hub:4444
      SELENIUM_SUT_URL: http://employees-app:8080
    entrypoint:
      [
        "/opt/wait/wait-for-it.sh",
        "-t",
        "120",
        "employees-app:8080",
        "--",
        "./mvnw",
        "test",
      ]
```

```shell
mkdir wait
cd wait
curl https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o wait-for-it.sh
cd ..
```

`wait-for-it.sh` nélkül:

Már a `Dockerfile` is tartalmazhat `HEALTHCHECK` bejegyzést.
Kerüljük a `curl` használatát, kisebb a [BusyBox](https://busybox.net/).

```
FROM eclipse-temurin:17
RUN apt update && apt install -y busybox && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY target/*.jar employees.jar
HEALTHCHECK CMD busybox wget -qO- http://localhost:8080/actuator/health || exit 1
CMD ["java", "-jar", "employees.jar"]
```

```yaml
version: "3"
services:
  selenium-hub:
    image: selenium/hub
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"

  chrome:
    image: selenium/node-chrome
    volumes:
      - /dev/shm:/dev/shm
    depends_on:
      - selenium-hub
    environment:
      SE_EVENT_BUS_HOST: selenium-hub
      SE_EVENT_BUS_PUBLISH_PORT: 4442
      SE_EVENT_BUS_SUBSCRIBE_PORT: 4443
    expose:
      - "5900"
    privileged: true

  chrome-video:
    image: selenium/video:ffmpeg-4.3.1-20210527
    volumes:
      - ./videos:/videos
    depends_on:
      - chrome
    environment:
      DISPLAY_CONTAINER_NAME: chrome
      FILE_NAME: chrome-video.mp4

  mariadb:
    image: mariadb
    expose:
      - 3306
    environment:
      MARIADB_DATABASE: employees
      MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: "yes"
      MARIADB_USER: employees
      MARIADB_PASSWORD: employees
    healthcheck:
      test:
        [
          "CMD",
          "healthcheck.sh",
          "--su-mysql",
          "--connect",
          "--innodb_initialized",
        ]
      interval: 5s
      retries: 3
      timeout: 30s

  employees-app:
    image: employees:1.0.0
    expose:
      - 8080
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      SPRING_DATASOURCE_URL: "jdbc:mariadb://mariadb:3306/employees"
      SPRING_DATASOURCE_USERNAME: employees
      SPRING_DATASOURCE_PASSWORD: employees

  employees-selenium:
    build: .
    image: employees-selenium
    volumes:
      - ./surefire-reports:/tests/target/surefire-reports
    depends_on:
      employees-app:
        condition: service_healthy
    environment:
      SELENIUM_DRIVER: RemoteWebDriver
      SELENIUM_HUB_URL: http://selenium-hub:4444
      SELENIUM_SUT_URL: http://employees-app:8080
```

```shell
docker compose up --abort-on-container-exit
```

- a `--abort-on-container-exit` kapcsoló hatására leállítja az összeset, ha egy is leáll
- Videó
- Report

## SonarQube - gyakorlat

```shell
docker run --name sonarqube -d -p 9000:9000 sonarqube:lts
```

- `admin`/`admin` -> `admin` / `admin12AA`
- My Account / Security / Generate Tokens

## Projekt elemzése SonarScanner Maven pluginnal - gyakorlat

```shell
mvnw sonar:sonar "-Dsonar.login=token"
```

- Elemzés eredménye
- Tesztlefedettség eredménye

## Integrációs tesztek SonarScanner Maven pluginnal - gyakorlat

```xml
<sonar.junit.reportPaths>
  ${project.basedir}/target/surefire-reports/,${project.basedir}/target/failsafe-reports/
</sonar.junit.reportPaths>
```

## SonarQube Quality Profiles - gyakorlat

## SonarQube Quality Gates - gyakorlat

## SonarQube Quality Gate Mavennel - gyakorlat

Maven bevárás:

```shell
mvnw sonar:sonar "-Dsonar.login=token" "-Dsonar.qualitygate.wait=true"
```

## IDEA SonarLint plugin - gyakorlat

## OWASP dependency check Mavennel - gyakorlat

```xml
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>8.2.1</version>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

```shell
mvnw verify
```

Vagy explicit futtatás:

```shell
mvnw org.owasp:dependency-check-maven:check
```

Lásd `target/dependency-check-report.html`

Internet hozzáférés szükséges, de meg lehet adni, hogy a fájlokat máshonnan, pl.
belső hálózatból töltse le

Fájlok:

```
[DEBUG] Settings.getDataFile() - file: '[JAR]/../../dependency-check-data/11.0'
[DEBUG] Settings.getDataFile() - transforming filename
[DEBUG] Settings.getDataFile() - jar file: '%HOME%\.m2\repository\org\owasp\dependency-check-utils\12.1.6'
[DEBUG] Settings.getDataFile() - returning: '%HOME%\.m2\repository\org\owasp\dependency-check-utils\12.1.6\..\..\dependency-check-data\11.0'
```

200 MB, 26 perc API key nélkül, 4 perc API key-jel
