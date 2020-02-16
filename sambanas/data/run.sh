#!/usr/bin/env bashio


WORKGROUP=$(bashio::config 'workgroup')
INTERFACE=$(bashio::config 'interface')
ALLOW_HOSTS=$(bashio::config "allow_hosts | join(\" \")")
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
DELETE_VETO_FILES="no"
VETO_FILES=$(bashio::config "veto_files | join(\"/\")")
if bashio::config.has_value 'veto_files'; then
    VETO_FILES="/$VETO_FILES/"
    DELETE_VETO_FILES="yes"
fi

WAIT_PIDS=()

# Check Login data
if ! bashio::config.has_value 'username' || ! bashio::config.has_value 'password'; then
    bashio::exit.nok "No valid login data inside options!"
fi

# Read hostname from API or setting default "hassio"
NAME=$(bashio::info.hostname)
if bashio::var.is_empty "${NAME}"; then
    bashio::log.warning "Can't read hostname, using default."
    NAME="hassio"
fi
bashio::log.info "Hostname: ${NAME}"

# Mount external drive
if bashio::config.has_value 'moredisks'; then
    MOREDISKS=$(bashio::config 'moredisks')
    mkdir -p /dev_ && \
    mount /dev_ && \
    bashio::log.info "More Disks mounting.. ${MOREDISKS}" && \
    for disk in $MOREDISKS 
    do
        bashio::log.info "Mount ${disk}"
        mkdir -p /$disk && \
            mount -t auto /dev_/disk/by-label/$disk /$disk -o nosuid,relatime,noexec && \
            cat /tmp/moredisk.smb.conf >> /etc/smb.conf && \
            sed -i "s|%%DISKNAME%%|${disk}|g" /etc/smb.conf && \
            bashio::log.info "Success!"   
    done || \
    bashio::log.warning "Protection mode is ON. Unable to mount external drivers!"
fi


# Setup config
sed -i "s|%%WORKGROUP%%|${WORKGROUP}|g" /etc/smb.conf
sed -i "s|%%NAME%%|${NAME}|g" /etc/smb.conf
sed -i "s|%%INTERFACE%%|${INTERFACE}|g" /etc/smb.conf
sed -i "s|%%USERNAME%%|${USERNAME}|g" /etc/smb.conf
sed -i "s#%%ALLOW_HOSTS%%#${ALLOW_HOSTS}#g" /etc/smb.conf
sed -i "s|%%VETO_FILES%%|${VETO_FILES}|g" /etc/smb.conf
sed -i "s|%%DELETE_VETO_FILES%%|${DELETE_VETO_FILES}|g" /etc/smb.conf

# Init users
addgroup "${USERNAME}"
adduser -D -H -G "${USERNAME}" -s /bin/false "${USERNAME}"
# shellcheck disable=SC1117
echo -e "${PASSWORD}\n${PASSWORD}" | smbpasswd -a -s -c /etc/smb.conf "${USERNAME}"




# Start samba
nmbd -F -S -s /etc/smb.conf &
WAIT_PIDS+=($!)

smbd -F -S -s /etc/smb.conf &
WAIT_PIDS+=($!)

# mDNS publish
bashio::log.info "mDNS registred as ${NAME}/SAMBA service!" 
avahi-publish-service -v -s $NAME _smb._tcp 445 &
WAIT_PIDS+=($!)  

# Register stop
function stop_samba() {
    bashio::log.info "Kill Processes..."
    kill -15 "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
    bashio::log.info "Unmount drivers."
    umount -a
    bashio::log.info "Done."
}
trap "stop_samba" SIGTERM SIGHUP

# Wait until all is done
wait "${WAIT_PIDS[@]}"