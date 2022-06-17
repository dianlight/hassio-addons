#!/usr/bin/with-contenv bashio
# ==============================================================================
# Mounting external HD and modify the smb.conf
# ==============================================================================
readonly CONF="/usr/share/tempio/smb.gtpl"
declare moredisks
declare interface
declare ipaddress
declare ssh_private_key
declare remote_mount
declare devpath

# mount a disk from parameters
function mount_disk() {
     devpath=/dev/disk/by-label
     if [[ $disk == id:* ]] ; then
          bashio::log.info "Disk ${disk:3} is an ID"
          devpath=/dev/disk/by-id
          disk=${disk:3}
     fi 

     mkdir -p /media/$disk

     if [ "$remote_mount" = true ] ; then
       ssh root@${ipaddress%/*} -p 22222 -o "StrictHostKeyChecking no" "mount -t auto $devpath/$disk /mnt/data/supervisor/media/$disk -o nosuid,relatime,noexec" \
          && echo $disk >> /tmp/remote_mount
     fi || bashio::log.warning "Host Mount ${$disk} Fail!"
     mount -t auto $devpath/$disk /media/$disk -o nosuid,relatime,noexec \
       && echo $disk >> /tmp/local_mount
}

# Mount external drive
bashio::log.info "Protection Mode is $(bashio::addon.protected)"
if $(bashio::addon.protected) && bashio::config.has_value 'moredisks' ; then
     bashio::log.warning "MoreDisk ignored because ADDON in Protected Mode!"
     bashio::config.suggest "protected" "moredisk only work when Protection mode is disabled"
elif bashio::config.has_value 'moredisks'; then
     bashio::log.info "MoreDisk option found!"

     # Check Host Ssh config
     remote_mount=false
    
     if bashio::config.true 'medialibrary.enable' ; then
          bashio::log.info "MediaLibrary option found!"
          if bashio::config.is_empty 'medialibrary.ssh_private_key'  ; then
               bashio::log.warning "SSH Private Key Host not found!"
               bashio::config.suggest "ssh_private_key" "SSH Private Key is required for enable medialibrary"
               bashio::log.waring "MediaLibrary due error in config!"
          else 
               interface=$(bashio::network.name)
               ipaddress=$(bashio::network.ipv4_address ${interface})
               ssh_private_key=$(bashio::config 'medialibrary.ssh_private_key')
               mkdir -p /root/.ssh

               #bashio::log.info "SSH Key: ${ssh_private_key}"
               echo "${ssh_private_key}" > /root/.ssh/id_rsa
               #cat /root/.ssh/id_rsa
               chmod ag-rw /root/.ssh/id_rsa
               ssh root@${ipaddress%/*} -p 22222 -o "StrictHostKeyChecking no" "date"
               if [ $? -eq 0 ]; then
                    bashio::log.info "SSH connection to ${ipaddress%/*}:22222 OK"
                    remote_mount=true
               else
                    bashio::log.warning "SSH connection to ${ipaddress%/*}:22222 FAILED"
                    bashio::log.warning "MediaLibrary due error in config!"
               fi
          fi
     else 
          bashio::log.info "MediaLibrary disabled in config. Disk are mounted only for this addon!"     
     fi

     ## List available Disk with Labels and Id 
     if bashio::config.true 'available_disks_log' ; then
          LABELS=$(ls /dev/disk/by-label | grep -v hassos || true )
          bashio::log.info "Available Disk Labels:\n ${LABELS}"
     fi

     MOREDISKS=$(bashio::config 'moredisks')
     bashio::log.info "More Disks mounting.. ${MOREDISKS}" && \
     for disk in $MOREDISKS 
     do
         bashio::log.info "Mount ${disk}"
         mount_disk && \
             cat /tmp/moredisk.smb.gtpl >> "${CONF}" && \
             sed -i "s|%%DISKNAME%%|${disk}|g" "${CONF}" && \
             bashio::log.info "Success!"   
     done || \
     bashio::log.warning "Unable to mount external drivers!"
fi
