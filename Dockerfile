FROM alpine:3.16
LABEL maintainer="sameer@damagehead.com"

ENV SQUID_VERSION=5.5-r0 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=squid

RUN apk update \
    && apk add bash squid=${SQUID_VERSION}

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3128/tcp
ENTRYPOINT ["/sbin/entrypoint.sh"]
