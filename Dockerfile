FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
RUN apk update && apk add curl
ARG NEXUS_USER
ARG NEXUS_PASS
ARG NEXUS_URL
ARG VERSION
RUN curl -u ${NEXUS_USER}:${NEXUS_PASS} \
  -o cal.jar \
  ${NEXUS_URL}/repository/maven-releases/com/example/calculator-java/${VERSION}/calculator-java-${VERSION}.jar
ENTRYPOINT ["java","-jar","cal.jar"]
