#!/usr/bin/with-contenv bashio
# ==============================================================================
# Umount all drivers.
# ==============================================================================
bashio::log.info "Unmount drivers."
umount -a
bashio::log.info "Done."