FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN apk update && apk add curl

ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG NEXUS_URL
ARG ARTIFACT_VERSION

RUN curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} \
    -o cal.jar \
    ${NEXUS_URL}/repository/maven-releases/com/example/calculator-java/${ARTIFACT_VERSION}/calculator-java-${ARTIFACT_VERSION}.jar

ENTRYPOINT ["java","-jar","cal.jar"]
