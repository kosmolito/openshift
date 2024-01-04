FROM alpine:latest

ENV MARIADB_HOST "change_me"
ENV MARIADB_DATABASE "change_me"
ENV MARIADB_USER "change_me"
ENV MARIADB_PASSWORD "change_me"
ENV ACCESS_KEY_ID "change_me"
ENV SECRET_ACCESS_KEY "change_me"
ENV BUCKET_NAME "change_me"

COPY ./run.sh /tmp/run.sh

RUN mkdir -p /tmp/db-backups /.aws && \
    chgrp -R 0 /tmp/db-backups /.aws && \
    chmod -R g=u /tmp/db-backups /.aws

VOLUME /tmp/db-backups
WORKDIR /tmp/db-backups

RUN apk add --no-cache mariadb-client py3-pip bash curl && pip install awscli

USER 1001

CMD ["/bin/bash", "/tmp/run.sh"]