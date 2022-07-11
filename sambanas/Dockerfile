ARG BUILD_FROM

FROM $BUILD_FROM as wsdd2-builder

RUN apk add --no-cache make gcc libc-dev linux-headers && wget -O - https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz | tar zxvf - \
    && cd wsdd2-master && make

FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Setup base
ARG BUILD_ARCH
ARG CLI_VERSION
RUN apk add --no-cache \
    samba-common-tools \
    samba-server \
    dbus \
    exfat-utils \
    fuse \
    fuse-exfat \
    fuse-exfat-utils \
    btrfs-progs \
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
    figlet \
    findmnt 

# WSDD2
COPY --from=wsdd2-builder /wsdd2-master/wsdd2 /usr/sbin 

# WSDD
RUN apk add --no-cache \
    wsdd \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ 

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
