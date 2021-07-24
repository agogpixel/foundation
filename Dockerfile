ARG alpine_version=latest
FROM alpine:${alpine_version}

ARG alpine_version=latest
ARG username=non-root
ARG uid=1000
ARG gid=1000

COPY install.sh /tmp/
RUN apk --update-cache upgrade && \
    sh /tmp/install.sh "${alpine_version}" "${username}" "${uid}" "${gid}" && \
    rm -f /tmp/install.sh

ENTRYPOINT ["entrypoint.sh"]
