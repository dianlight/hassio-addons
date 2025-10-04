ARG BUILD_FROM
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ARG SAMBA_VERSION

#ARG HDDTEMP_VERSION

# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS builder_wsdd

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache make \
    gcc libc-dev linux-headers build-base autoconf automake git \
    python3-dev musl-dev poetry go lsblk eudev 

ARG BUILD_ARCH

RUN cd / \
    && wget -q -O - "https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz" | tar zxvf - \
    && cd wsdd2-master \
    && wget -q -O - https://raw.githubusercontent.com/openwrt/packages/refs/heads/master/net/wsdd2/patches/010-gcc14.patch | patch -p1 \
    && make

# Samba Builder Stage (only if SAMBA_VERSION is not "distribution")
# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS samba_builder

ARG SAMBA_VERSION

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Install Samba build dependencies only if we need to compile Samba
RUN if [ "$SAMBA_VERSION" != "distribution" ]; then \
    apk add --no-cache \
    build-base \
    python3-dev \
    talloc-dev \
    tevent-dev \
    tdb-dev \
    popt-dev \
    iniparser-dev \
    libarchive-dev \
    libbsd-dev \
    openldap-dev \
    cups-dev \
    avahi-dev \
    gnutls-dev \
    libgcrypt-dev \
    gpgme-dev \
    acl-dev \
    attr-dev \
    libcap-dev \
    jansson-dev \
    json-c-dev \
    krb5-dev \
    openssl-dev \
    zlib-dev \
    perl \
    perl-parse-yapp \
    pkgconfig \
    flex \
    bison \
    docbook-xsl \
    libxslt \
    python3 \
    py3-pip \
    git \
    cmocka-dev \
    && python3 -m pip install --no-cache-dir dnspython==2.8.0 \
    && cd /tmp \
    && wget -q "https://download.samba.org/pub/samba/stable/samba-${SAMBA_VERSION}.tar.gz" \
    && tar -xzf "samba-${SAMBA_VERSION}.tar.gz" \
    && cd "samba-${SAMBA_VERSION}" \
    && ./configure \
    --prefix=/usr/local/samba \
    --sysconfdir=/etc/samba \
    --localstatedir=/var \
    --with-configdir=/etc/samba \
    --with-lockdir=/var/lock/samba \
    --with-piddir=/var/run/samba \
    --with-cachedir=/var/cache/samba \
    --with-privatedir=/etc/samba/private \
    --with-logfilebase=/var/log/samba \
    --with-pammodulesdir=/lib/security \
    --enable-fhs \
    --without-ad-dc \
    --disable-fault-handling \
    --with-shared-modules='!vfs_snapper' \
    --without-systemd \
    --disable-python \
    --without-ldb-lmdb \
    --without-pam \
    --disable-cups \
    --without-gettext \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/samba-* \
    ; fi
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

# Wait more time to allow gracefull shutdown
ENV S6_KILL_GRACETIME=30000
ENV S6_SYNC_DISKS=1

# Setup base
ARG BUILD_ARCH
ARG CLI_VERSION
ARG SRAT_VERSION
ARG SAMBA_VERSION

# Install Samba either from distribution packages or from compiled source
RUN if [ "$SAMBA_VERSION" = "distribution" ]; then \
    apk add --no-cache \
    samba-common-tools \
    samba-server \
    samba-client; \
    else \
    # Create necessary directories for compiled Samba \
    mkdir -p /usr/local/samba; \
    fi

# Copy compiled Samba binaries if they exist (when SAMBA_VERSION != "distribution")
COPY --from=samba_builder /usr/local/samba/ /usr/local/samba/

# Set up Samba paths and symlinks for compiled version
RUN if [ "$SAMBA_VERSION" != "distribution" ] && [ -d "/usr/local/samba/bin" ]; then \
    # Create symlinks for main Samba binaries \
    ln -sf /usr/local/samba/bin/smbd /usr/sbin/smbd && \
    ln -sf /usr/local/samba/bin/nmbd /usr/sbin/nmbd && \
    ln -sf /usr/local/samba/bin/smbcontrol /usr/bin/smbcontrol && \
    ln -sf /usr/local/samba/bin/smbclient /usr/bin/smbclient && \
    ln -sf /usr/local/samba/bin/smbpasswd /usr/bin/smbpasswd && \
    ln -sf /usr/local/samba/bin/testparm /usr/bin/testparm && \
    # Add Samba to PATH \
    echo "export PATH=\"/usr/local/samba/bin:/usr/local/samba/sbin:\$PATH\"" >> /etc/profile && \
    # Create necessary runtime directories \
    mkdir -p /var/lib/samba /var/log/samba /var/cache/samba /etc/samba/private; \
    fi

RUN apk add --no-cache \
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
    curl \
    unzip \
    findmnt \
    ntfs-3g-progs \
    sysstat \
    hdparm \
    smartmontools \
    #    wsdd \
    udisks2 \
    libcap \
    hd-idle \
    fuse3 \
    #    py3-pip \
    lsblk \
    socat \
    figlet \
    shadow \
    # avahi \
    # avahi-compat-libdns_sd \
    # avahi-tools \
    envsubst \
    ethtool \
    erofs-utils \
    squashfs-tools


# hadolint ignore=DL3018,DL3003
RUN if [ "$BUILD_ARCH" != "armv7" ]; then \
    apk add --no-cache apfs-fuse; \
    fi

# AVAHI (Remove all services)
# RUN rm -f /etc/avahi/services/*.service 

# WSDD2
COPY --from=builder_wsdd /wsdd2-master/wsdd2 /usr/sbin

# HA API
RUN curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha 

# SAMBA Config
RUN  mkdir -p /var/lib/samba \
    && touch \
    /etc/samba/lmhosts \
    /var/lib/samba/account_policy.tdb \
    /var/lib/samba/registry.tdb \
    /var/lib/samba/winbindd_idmap.tdb

# SRAT
RUN SRAT_ARCH_SUFFIX="${BUILD_ARCH}"; \
    if [ "${BUILD_ARCH}" = "amd64" ]; then \
    SRAT_ARCH_SUFFIX="x86_64"; \
    fi; \
    curl -Lso /tmp/srat.zip "https://github.com/dianlight/srat/releases/download/${SRAT_VERSION}/srat_${SRAT_ARCH_SUFFIX}.zip" \
    && unzip -o /tmp/srat.zip -d /usr/local/bin/ \
    && chmod a+x /usr/local/bin/srat* \
    && rm -f /tmp/srat.zip

# ENABLE FUSE APFS
RUN ln -s /usr/sbin/apfs-fuse /usr/sbin/mount.apfs

# Copy data
COPY rootfs /

# Set the exec flags correctly
RUN find /etc/s6-overlay -type f -print0 | xargs -0 chmod a+x

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD smbcontrol smbd ping || exit 1

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
