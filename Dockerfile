ARG alpine_version=latest
FROM alpine:${alpine_version}

ARG alpine_version=latest
ARG username=non-root
ARG uid=1000
ARG gid=1000
ARG entrypoint_path=/usr/local/bin/entrypoint.sh
ARG entrypointd_path=/usr/local/share/entrypoint.d
ARG run_container_path=/usr/local/bin/run-container.sh
ARG runit_path=/etc/runit
ARG service_path=/etc/service

ENV FOUNDATION_ALPINE_VERSION="${alpine_version}"
ENV FOUNDATION_USERNAME="${username}"
ENV FOUNDATION_UID="${uid}"
ENV FOUNDATION_GID="${gid}"
ENV FOUNDATION_ENTRYPOINT_PATH="${entrypoint_path}"
ENV FOUNDATION_ENTRYPOINTD_PATH="${entrypointd_path}"
ENV FOUNDATION_RUN_CONTAINER_PATH="${run_container_path}"
ENV FOUNDATION_RUNIT_PATH="${runit_path}"
ENV FOUNDATION_RUNIT_INITD_PATH="${runit_path}/init.d"
ENV FOUNDATION_RUNIT_TERMD_PATH="${runit_path}/term.d"
ENV FOUNDATION_SERVICE_PATH="${service_path}"

COPY install.sh /tmp/
RUN apk --update-cache upgrade && \
    sh /tmp/install.sh \
        "${FOUNDATION_ALPINE_VERSION}" \
        "${FOUNDATION_USERNAME}" \
        "${FOUNDATION_UID}" \
        "${FOUNDATION_GID}" \
        "${FOUNDATION_ENTRYPOINT_PATH}" \
        "${FOUNDATION_ENTRYPOINTD_PATH}" \
        "${FOUNDATION_RUN_CONTAINER_PATH}" \
        "${FOUNDATION_RUNIT_PATH}" \
        "${FOUNDATION_RUNIT_INITD_PATH}" \
        "${FOUNDATION_RUNIT_TERMD_PATH}" \
        "${FOUNDATION_SERVICE_PATH}" && \
    rm -f /tmp/install.sh

ENTRYPOINT ["entrypoint.sh"]
