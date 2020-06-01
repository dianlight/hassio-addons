#!/usr/bin/with-contenv bashio
# ==============================================================================
# Mounting external HD and modify the smb.conf
# ==============================================================================
readonly CONF="/etc/samba/smb.conf"
declare moredisks

# Mount external drive
if bashio::config.has_value 'moredisks'; then
     bashio::log.warning "MoreDisk option found!"

     MOREDISKS=$(bashio::config 'moredisks')
##    mkdir -p /dev_ && \
     mount /dev_ && \
     bashio::log.info "More Disks mounting.. ${MOREDISKS}" && \
     for disk in $MOREDISKS 
     do
         bashio::log.info "Mount ${disk}"
         mkdir -p /$disk && \
             mount -t auto /dev_/disk/by-label/$disk /$disk -o nosuid,relatime,noexec && \
             cat /tmp/moredisk.smb.conf >> "${CONF}" && \
             sed -i "s|%%DISKNAME%%|${disk}|g" "${CONF}" && \
             bashio::log.info "Success!"   
     done || \
     bashio::log.warning "Protection mode is ON. Unable to mount external drivers!"
fi