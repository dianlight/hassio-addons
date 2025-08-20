#!/usr/bin/with-contenv sh

echo "-> Loading kernel modules..."

# Load necessary modules
MOD_FS=$(ls /lib/modules/$(uname -r)/kernel/fs)

for mod in $MOD_FS; do
    modprobe "$mod"
done

echo "-> Done."

exit 0