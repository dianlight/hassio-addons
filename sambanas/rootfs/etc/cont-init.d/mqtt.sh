#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the MQTT config for running
# ==============================================================================
readonly CONF="/root/.config/mosquitto_pub"
readonly CONF_SUB="/root/.config/mosquitto_sub"
declare host
declare username
declare password
declare port
declare topic
declare moredisks

topic=$(bashio::config 'mqtt_topic');if [ "$topic" = "null" ]; then topic="sambanas"; fi;
host=$(bashio::config 'mqtt_host');if [ "$host" = "null" ]; then host=$(bashio::services "mqtt" "host"); fi
username=$(bashio::config 'mqtt_username');if [ "$username" = "null" ]; then username=$(bashio::services "mqtt" "username"); fi
password=$(bashio::config 'mqtt_password');if [ "$password" = "null" ]; then password=$(bashio::services "mqtt" "password"); fi
port=$(bashio::config 'mqtt_port');if [ "$port" = "null" ]; then port=$(bashio::services "mqtt" "port"); fi

#bashio::log.info "MQTT config ${host}:${port} ${username}:${password}"

[ -z "$host" ] && bashio::log.warn "No MQTT Server found. Homeassistant integration can't work!"

if bashio::var.has_value "host" && ! bashio::config.false "mqtt_enable" && [ -n "$host" ]; then
    {
        echo "-h ${host}"
        echo "--username ${username}"
        echo "--pw ${password}"
        echo "--port ${port}"
    } > "${CONF}"
    {
        echo "-h ${host}"
        echo "--username ${username}"
        echo "--pw ${password}"
        echo "--port ${port}"
    } > "${CONF_SUB}"
fi
