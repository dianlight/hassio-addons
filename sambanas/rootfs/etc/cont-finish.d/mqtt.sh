#!/usr/bin/with-contenv bashio
# ==============================================================================
# MQTT autodiscovery cleanup
# ==============================================================================
declare topic

if ! bashio::config.true "autodiscovery.disable_autoremove"; then
    bashio::log.info "MQTT cleanup."
    topic=$(bashio::config 'mqtt_topic');if [ "$topic" = "null" ]; then topic="sambanas"; fi;
    mosquitto_sub -t "homeassistant/sensor/${topic}/+/config" -v --remove-retained  --retained-only -W 5
    bashio::log.info "MQTT cleanup Done."
fi