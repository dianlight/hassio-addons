ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Setup base
RUN apk add --no-cache \
        samba-common-tools \
        samba-server \
        exfat-utils \
        fuse-exfat \
        udev \
        hwids-udev \
        device-mapper-udev \
        attr \
        e2fsprogs \
        util-linux \
        e2fsprogs-extra \
        avahi \
        avahi-tools


# Copy data
COPY data/run.sh /
COPY data/smb.conf /etc/
COPY data/moredisk.smb.conf /tmp/
RUN echo "devtmpfs /dev_ devtmpfs rw,relatime,size=1965288k,nr_inodes=182901,mode=755 0 0" >> /etc/fstab

CMD [ "/run.sh" ]