#!/usr/bin/with-contenv sh

if [ ! -f "/etc/samba/smb.conf" ]; then
  # s6-init fallirà se uno script in cont-init.d esce con un codice diverso da 0
  echo "FATAL: /etc/samba/smb.conf does not exist. Cannot start services."
  exit 1
fi