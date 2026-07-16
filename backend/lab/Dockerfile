# Backend Spring Boot (Java 21). Build multi-stage: compila com Maven e roda num JRE enxuto.

# ---- Estágio 1: build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copia só o pom primeiro; o cache de dependências (.m2) é reaproveitado entre builds
# via cache mount, então mudar o código-fonte não força rebaixar tudo de novo.
COPY pom.xml .
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q clean package -DskipTests

# ---- Estágio 2: runtime ----
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Usuário não-root por segurança.
RUN addgroup -S app && adduser -S app -G app

COPY --from=build /app/target/*.jar app.jar
USER app

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
