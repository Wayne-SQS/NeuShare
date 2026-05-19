# 后端多阶段构建
FROM maven:3.6-jdk-8-slim AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline 2>/dev/null || true
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:8-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
RUN mkdir -p uploads
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
