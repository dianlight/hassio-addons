#!/usr/bin/with-contenv bashio
# ==============================================================================
# Mounting external HD and modify the smb.conf
# ==============================================================================
readonly CONF="/usr/share/tempio/smb.gtpl"
declare moredisks

# Mount external drive
bashio::log.info "Protection Mode is $(bashio::addon.protected)"
if $(bashio::addon.protected) && bashio::config.has_value 'moredisks' ; then
     bashio::log.warning "MoreDisk ignored because ADDON in Protected Mode!"
     bashio::config.suggest "protected" "moredisk only work when Protection mode is disabled"
elif bashio::config.has_value 'moredisks'; then
     bashio::log.warning "MoreDisk option found!"

     MOREDISKS=$(bashio::config 'moredisks')
#     mount /dev_ && \
     bashio::log.info "More Disks mounting.. ${MOREDISKS}" && \
     for disk in $MOREDISKS 
     do
         bashio::log.info "Mount ${disk}"
         mkdir -p /$disk && \
             mount -t auto /dev/disk/by-label/$disk /$disk -o nosuid,relatime,noexec && \
             cat /tmp/moredisk.smb.gtpl >> "${CONF}" && \
             sed -i "s|%%DISKNAME%%|${disk}|g" "${CONF}" && \
             bashio::log.info "Success!"   
     done || \
     bashio::log.warning "Unable to mount external drivers!"
fi
