#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the MQTT config for running
# ==============================================================================
readonly CONF="/root/.config/mosquitto_pub"
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

if bashio::var.has_value "host"; then
    {
        echo "-h ${host}"
        echo "--username ${username}"
        echo "--pw ${password}"
        echo "--port ${port}"
    } > "${CONF}"

    # Home assistant auto discovery    
    if [ -f /root/.config/mosquitto_pub ]; then
        moredisks=$(bashio::config 'moredisks')
        a=({a..z})
        bashio::log.info "Sending MQTT autodiscovery..."
        for disk in config addons ssl share backup media $moredisks 
        do
           mosquitto_pub -r -t "homeassistant/sensor/${topic}${a}S/config" -m \
            "{\"name\": \"${topic} Size /${disk}\", \"unit_of_measurement\": \"Kb\", \"value_template\": \"{{ value_json.size_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
           mosquitto_pub -r -t "homeassistant/sensor/${topic}${a}U/config" -m \
            "{\"name\": \"${topic} Used /${disk}\", \"unit_of_measurement\": \"Kb\", \"value_template\": \"{{ value_json.used_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
           mosquitto_pub -r -t "homeassistant/sensor/${topic}${a}A/config" -m \
            "{\"name\": \"${topic} Available /${disk}\", \"unit_of_measurement\": \"Kb\", \"value_template\": \"{{ value_json.available_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
           mosquitto_pub -r -t "homeassistant/sensor/${topic}${a}Up/config" -m \
            "{\"name\": \"${topic} Use% /${disk}\", \"unit_of_measurement\": \"%\", \"value_template\": \"{{ value_json.use_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
           a=("${a[@]:1}")
        done
    fi
fi
