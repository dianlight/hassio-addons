ARG BUILD_FROM
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# hadolint ignore=DL3006
FROM ${BUILD_FROM} as builder

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    curl \
    npm \
    nodejs

# Copy data
COPY gui /tmp/gui

RUN cd /tmp/gui && \
    ls -al && \
    npm install && \
    npm run build 

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment variables
ENV \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    HOME="/root" \
    LANG="C.UTF-8" \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_FIND_LINKS=https://wheels.home-assistant.io/musllinux/ \
    PIP_NO_CACHE_DIR=1 \
    PIP_PREFER_BINARY=1 \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    YARN_HTTP_TIMEOUT=1000000 \
    TERM="xterm-256color"


# Setup base
ARG BUILD_ARCH
ARG CLI_VERSION
ARG PYTHON_VERSION

RUN apk add --no-cache \
    curl \
    git
#    pkgconf \
#    gcc \
#    g++ \
#    make \
#    zlib-dev \
#    zlib \
#    libffi-dev \
#    libffi \
#    musl-dev \
#    musl \
#    openssl3-dev \
#    openssl3 \
#    sqlite-dev \
#    sqlite

## download and extract python sources build python and remove left-over sources
#RUN cd /opt \
#    && curl -s -L "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" | tar xzf - \
#    && cd "/opt/Python-${PYTHON_VERSION}" \
#    && ./configure --prefix=/usr --enable-optimizations --with-ensurepip=install \
#    && make install \
#    && apk del \
#    pkgconf \
#    gcc \
#    g++ \
#    make \
#    zlib-dev \
#    libffi-dev \
#    musl-dev \
#    openssl3-dev \
#    && rm -rf "/opt/Python-${PYTHON_VERSION}"

# HA API
RUN curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha

# Copy data
COPY rootfs /

COPY --from=builder /tmp/gui/dist/ /opt/static

# Python
#COPY --from=PythonBuilder "/opt/Python-${PYTHON_VERSION}" "/opt/Python-${PYTHON_VERSION}"
#RUN ls -al /opt && cd "/opt/Python-${PYTHON_VERSION}" \
#    && make install \
#    && cd .. \
#    && rm -rf "Python-${PYTHON_VERSION}"
#COPY --from=PythonBuilder /usr/lib/python3.12 /usr/lib/python3.12
#COPY --from=PythonBuilder /usr/include/python3.12 /usr/include/python3.12
#COPY --from=PythonBuilder /usr/share/man/man1/python* /usr/share/man/man1/
#COPY --from=PythonBuilder /usr/bin/*  /usr/bin/


# BESIM
WORKDIR /opt/BeSIM

RUN unset PIP_EXTRA_INDEX_URL \
    && unset PIP_FIND_LINKS \
    && pip3 install --no-cache-dir -r requirements.txt \
    && rm -rf .git \
    && git clone --no-hardlinks --no-checkout https://github.com/dianlight/BeSIM-MQTT.git a.tmp \
    && mv a.tmp/.git .\
    && rm -rf a.tmp





#HEALTHCHECK \
#    CMD smbclient -L '\\localhost' -U '%' -m SMB3

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Lucio Tarantino <@dianlight>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Dianlight Add-ons" \
    org.opencontainers.image.authors="Lucio Tarantino <@dianlight>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/dianlight/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
