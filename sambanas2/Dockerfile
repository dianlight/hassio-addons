ARG BUILD_FROM
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ARG SAMBA_VERSION
ARG HA_CLI_VERSION

# QUIC Builder Stage (only if SAMBA_VERSION is not "distribution")
# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS quic_builder

ARG SAMBA_VERSION

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Create directory that will be copied (ensures COPY doesn't fail)
RUN mkdir -p /usr/local/quic

# Install QUIC build dependencies only if we need to compile Samba with QUIC support
RUN if [ "$SAMBA_VERSION" != "distribution" ]; then \
    apk add --no-cache \
    build-base \
    cmake \
    git \
    linux-headers \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    openssl-dev \
    gnutls-dev \
    elfutils-dev \
    && cd /tmp \
    && git clone --depth 1 --single-branch https://github.com/lxin/quic.git \
    && cd quic \
    && ./autogen.sh \
    && sed -i "s/as_fn_error \\\$? \"no kernel-devel found\" \"\\\$LINENO\" 5/echo \"Skipping kernel-devel check\"/" configure \
    && ./configure --prefix=/usr/local/quic --disable-kernel-check \
    && make -C libquic -j"$(nproc)" \
    && make -C libquic install \
    && strip /usr/local/quic/lib/*.so* 2>/dev/null || true \
    && rm -rf /tmp/quic \
    ; fi

# Samba Builder Stage (only if SAMBA_VERSION is not "distribution")
# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS samba_builder

ARG SAMBA_VERSION

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Create directory that will be copied (ensures COPY doesn't fail)
RUN mkdir -p /usr/local/samba

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
    wget \
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
    --without-ldap \
    --without-ldb-lmdb \
    --without-pam \
    --without-ads \
    --disable-cups \
    --disable-iprint \
    --disable-avahi  \
    --without-gettext \
    && make -j"$(nproc)" \
    && make install \
    && find /usr/local/samba -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true \
    && rm -rf /tmp/samba-* \
    ; fi

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment variables
ENV \
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
    S6_KILL_GRACETIME=30000 \
    S6_SYNC_DISKS=1 \
    TERM="xterm-256color"

# Setup base
ARG BUILD_ARCH
ARG HA_CLI_VERSION
ARG SRAT_VERSION
ARG SAMBA_VERSION

# Copy compiled binaries from builder stages
#COPY --from=builder_wsdd /usr/sbin/wsdd2 /usr/sbin/
COPY --from=quic_builder /usr/local/quic/ /usr/local/quic/
COPY --from=samba_builder /usr/local/samba/ /usr/local/samba/

# Install Samba - either from distribution packages or use compiled binaries
RUN if [ "$SAMBA_VERSION" = "distribution" ]; then \
    apk add --no-cache \
    samba-common-tools \
    samba-server \
    samba-client \
    openssl; \
    else \
    # Install runtime dependencies for compiled Samba \
    apk add --no-cache \
    openssl \
    gnutls \
    talloc \
    tevent \
    tdb \
    popt \
    iniparser \
    libarchive \
    libbsd \
    openldap \
    libgcrypt \
    gpgme \
    acl \
    attr \
    libcap \
    jansson \
    json-c \
    krb5-libs \
    zlib \
    && mkdir -p /usr/local/samba \
    # Create symlinks for all Samba binaries \
    && if [ -d "/usr/local/samba/sbin" ]; then \
    for file in /usr/local/samba/sbin/*; do \
    [ -e "$file" ] && ln -sf "$file" /usr/sbin/"$(basename "$file")"; \
    done; \
    fi \
    && if [ -d "/usr/local/samba/bin" ]; then \
    for file in /usr/local/samba/bin/*; do \
    [ -e "$file" ] && ln -sf "$file" /usr/bin/"$(basename "$file")"; \
    done; \
    fi \
    # Add Samba to PATH \
    && echo "export PATH=\"/usr/local/samba/bin:/usr/local/samba/sbin:\$PATH\"" >> /etc/profile \
    # Create necessary runtime directories \
    && mkdir -p /var/lib/samba /var/log/samba /var/cache/samba /etc/samba/private; \
    fi

# Install runtime dependencies first (needed for shell operations below)
RUN apk add --no-cache \
    readline \
    dbus \
    exfatprogs \
    btrfs-progs \
    xfsprogs \
    udev \
    binutils \
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
    udisks2 \
    libcap \
    hd-idle \
    fuse3 \
    lsblk \
    socat \
    figlet \
    shadow \
    envsubst \
    ethtool \
    erofs-utils \
    squashfs-tools \
    nfs-utils \
    ngtcp2 

# Install APFS support (not available for armv7)
# hadolint ignore=DL3018
RUN if [ "$BUILD_ARCH" != "armv7" ]; then \
    apk add --no-cache apfs-fuse \
    && ln -s /usr/sbin/apfs-fuse /usr/sbin/mount.apfs; \
    fi
# Install wsdd for WS-Discovery support
RUN wget -qO-  https://www.gershnik.com/alpine-repo/gershnik@hotmail.com-6643812b.rsa.pub \
    | tee /etc/apk/keys/gershnik@hotmail.com-6643812b.rsa.pub >/dev/null && \
    mkdir -p /etc/apk/repositories.d && \
    echo "https://www.gershnik.com/alpine-repo/main" \
    | tee /etc/apk/repositories.d/www.gershnik.com.list >/dev/null && \
    apk update && \
    apk add --no-cache wsdd-native

# Download and install Home Assistant CLI
RUN curl -fsSL -o /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${HA_CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha

# Download and install SRAT
RUN SRAT_ARCH_SUFFIX="${BUILD_ARCH}"; \
    if [ "${BUILD_ARCH}" = "amd64" ]; then \
    SRAT_ARCH_SUFFIX="x86_64"; \
    fi; \
    curl -fsSL -o /tmp/srat.zip "https://github.com/dianlight/srat/releases/download/${SRAT_VERSION}/srat_${SRAT_ARCH_SUFFIX}.zip" \
    && unzip -o /tmp/srat.zip -d /usr/local/bin/ \
    && chmod a+x /usr/local/bin/srat* \
    && rm -f /tmp/srat.zip

# Initialize Samba configuration files
RUN mkdir -p /var/lib/samba \
    && touch \
    /etc/samba/lmhosts \
    /var/lib/samba/account_policy.tdb \
    /var/lib/samba/registry.tdb \
    /var/lib/samba/winbindd_idmap.tdb

# Copy data
COPY rootfs /

# Set executable permissions on s6-overlay scripts
RUN find /etc/s6-overlay -type f -exec chmod a+x {} +

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
