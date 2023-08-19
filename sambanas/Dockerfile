ARG BUILD_FROM
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

ARG HDDTEMP_VERSION

# hadolint ignore=DL3006
FROM $BUILD_FROM as builder

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache make gcc libc-dev linux-headers build-base autoconf automake musl

ARG BUILD_ARCH
ARG HDDTEMP_VERSION

RUN cd / && wget -q -O - "http://download.savannah.nongnu.org/releases/hddtemp/hddtemp-${HDDTEMP_VERSION}.tar.bz2" | tar jxvf - \
    && cd "hddtemp-${HDDTEMP_VERSION}" && ./configure --build=${BUILD_ARCH}-unknown-linux-gnu && make && find /hddtemp-${HDDTEMP_VERSION} -name "hddtemp"

RUN cd / && wget -q -O - "https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz" | tar zxvf - \
    && cd wsdd2-master && make

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
RUN apk add --no-cache \
    samba-common-tools \
    samba-server \
    dbus \
    exfatprogs \
    btrfs-progs \
    xfsprogs \
    udev \
    eudev \
    hwids-udev \
    device-mapper-udev \
    attr \
    e2fsprogs \
    util-linux \
    e2fsprogs-extra \
    avahi \
    avahi-compat-libdns_sd \
    avahi-tools \
    curl \
    mosquitto-clients \
    openssh-client \
    findmnt \
    ntfs-3g-progs \
    sysstat \
    hdparm \
    smartmontools \
    wsdd \
    udisks2 \
    libcap \
    hd-idle

# HDDTEMP
ARG HDDTEMP_VERSION
COPY --from=builder /hddtemp-${HDDTEMP_VERSION}/src/hddtemp /usr/sbin
RUN  curl http://download.savannah.nongnu.org/releases/hddtemp/hddtemp.db -Lso /usr/share/misc/hddtemp.db

# WSDD2
COPY --from=builder /wsdd2-master/wsdd2 /usr/sbin


# SAMBA Config
RUN  mkdir -p /var/lib/samba \
    && touch \
    /etc/samba/lmhosts \
    /var/lib/samba/account_policy.tdb \
    /var/lib/samba/registry.tdb \
    /var/lib/samba/winbindd_idmap.tdb

# HA API
RUN curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha


#RUN echo "devtmpfs /dev_ devtmpfs rw,relatime,size=1965288k,nr_inodes=182901,mode=755 0 0" >> /etc/fstab

# Copy data
COPY rootfs /

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Dan Veitch <@danveitch76>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Dan Add-ons" \
    org.opencontainers.image.authors="Dan Veitch <@danveitch76>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/danveitch76/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
