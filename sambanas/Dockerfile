ARG BUILD_FROM
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
        udev \
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
    \
    && mkdir -p /var/lib/samba \
    && touch \
        /etc/samba/lmhosts \
        /var/lib/samba/account_policy.tdb \
        /var/lib/samba/registry.tdb \
        /var/lib/samba/winbindd_idmap.tdb \
    \    
    && curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha 

#RUN echo "devtmpfs /dev_ devtmpfs rw,relatime,size=1965288k,nr_inodes=182901,mode=755 0 0" >> /etc/fstab

# Copy data
COPY rootfs /

# Copy data
#COPY data/run.sh /
#COPY data/smb.conf /etc/
#COPY data/moredisk.smb.conf /tmp/
#
#CMD [ "/run.sh" ]