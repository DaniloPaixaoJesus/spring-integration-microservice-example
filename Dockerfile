FROM maven:3.8.1-openjdk-17-slim AS builder

COPY . /app
COPY ./m2/settings.xml /root/.m2/settings.xml
WORKDIR app

RUN ls

RUN mvn package
RUN mkdir /opt/jar && mv target/spring-integration-microservice-*.jar /opt/jar/application.jar

COPY pom.xml /opt/jar/
RUN ls /opt/jar

RUN rm -rf /app

FROM azul/zulu-openjdk-alpine:17

RUN mkdir /tmp/files

RUN apk update && apk upgrade
RUN apk --no-cache add bash tzdata
RUN apk del jq
RUN mkdir /opt/jar
RUN mkdir /tmp/certificates
ADD /pem/some-certificate-root /tmp/certificates/

COPY --from=builder /opt/jar/* /opt/jar/


USER root

RUN apk add --upgrade libx11
RUN echo "America/Sao_Paulo" > /etc/timezone

RUN keytool -import -keystore ${JAVA_HOME}/lib/security/cacerts -storepass changeit -noprompt -alias some-certificate-root -file /tmp/rds-cert/some-certificate-root.pem

ENV TZ America/Sao_Paulo
ENV LANG pt_BR.UTF-8
ENV LANGUAGE pt_BR:pt_br
ENV LC_ALL pt_BR.UTF-8

ENV JVM_XMS=128m
ENV JVM_XMX=256m

WORKDIR /opt/jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]