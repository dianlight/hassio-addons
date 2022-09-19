#!/usr/bin/with-contenv bashio
# ==============================================================================
# Umount all drivers.
# ==============================================================================
declare interface
declare ipaddress

interface=$(bashio::network.name)
ipaddress=$(bashio::network.ipv4_address ${interface})

if [[ -f /tmp/local_mount ]]; then
    bashio::log.info "Unmount drivers."
    while read -r line; do 
        bashio::log.info "Unmount ${line}"
        umount $line
   done < /tmp/local_mount
fi
if [[ -f /tmp/remote_mount ]]; then  
    bashio::log.info "Unmount Host drivers."
    while read -r line; do 
        bashio::log.info "Unmount Host ${line}"
        ssh root@${ipaddress%/*} -p 22222 -o "StrictHostKeyChecking no" "umount $line" || true
    done < /tmp/remote_mount
fi
bashio::log.info "Done."
