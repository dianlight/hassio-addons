#!/usr/bin/env bashio
declare topic
declare moredisks
declare status
declare fsdata

topic=$(bashio::config 'mqtt_topic');if [ "$topic" = "null" ]; then topic="sambanas"; fi;

while true; do
    # Create status message
    status="{\"1\":\"1\"";
    moredisks=$(bashio::config 'moredisks')
    for disk in config addons ssl share backup media $moredisks
    do
    #    bashio::log.info "Inspecting ${disk}"
        mapfile -t fsdata < <(df /$disk)
        fsd=(${fsdata[1]})
        status="$status, \"size_${disk,,}\":\"${fsd[1]}\""
        status="$status, \"used_${disk,,}\":\"${fsd[2]}\""
        status="$status, \"available_${disk,,}\":\"${fsd[3]}\""
        status="$status, \"use_${disk,,}\":\"${fsd[4]}\""
    done
    status="$status}"
    # Send status message
    mosquitto_pub -t "homeassistant/sensor/${topic}/state" -m "$status"
    # Sleep
    sleep 60
done
