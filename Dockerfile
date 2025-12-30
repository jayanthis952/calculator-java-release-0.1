# Base image with Java 17 JRE
FROM eclipse-temurin:17-jre-alpine

# Set working directory
WORKDIR /app

# Install curl (needed to download JAR from Nexus)
RUN apk update && apk add --no-cache curl

# Build arguments from Jenkinsfile
ARG NEXUS_USER
ARG NEXUS_PASS
ARG NEXUS_URL
ARG VERSION

# Download the JAR from Nexus using curl
RUN curl -fSL -u ${NEXUS_USER}:${NEXUS_PASS} \
    -o cal.jar \
    ${NEXUS_URL}/repository/maven-releases/com/example/calculator-java/${VERSION}/calculator-java-${VERSION}.jar

# Run the JAR
ENTRYPOINT ["java","-jar","cal.jar"]
