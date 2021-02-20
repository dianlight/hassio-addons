#!/usr/bin/env bashio
declare topic
declare moredisks
declare status
declare fsdata

topic=$(bashio::config 'mqtt_topic');if [ "$topic" = "null" ]; then topic="sambanas"; fi;
moredisks=$(bashio::config 'moredisks'); if $(bashio::addon.protected) ; then moredisks=""; fi;

# Home assistand MQTT old message remove

# 

# Home assistant auto discovery    
if [ -f /root/.config/mosquitto_pub ] && ! bashio::config.true "autodiscovery.disable_discovery"; then
#    moredisks=$(bashio::config 'moredisks')
    a=({a..z})
    if ! bashio::config.true "autodiscovery.disable_persistent"; then prs="-r";fi
    bashio::log.info "Sending MQTT autodiscovery..."
    device="\"device\":{\"identifiers\":[\"${topic}\"],\"name\": \"Samba Nas Sensors\", \"model\": \"Samba $(smbd -V)\", \"manufacturer\": \"@Dianlight\"},\"icon\":\"mdi:harddisk\"" 
    for disk in config addons ssl share backup media $moredisks 
    do
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_size/config" -m \
        "{\"name\": \"${topic} Size /${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_size_${disk,,}\",${device},\"value_template\": \"{{ value_json.size_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_used/config" -m \
        "{\"name\": \"${topic} Used /${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_used_${disk,,}\",${device}, \"value_template\": \"{{ value_json.used_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_available/config" -m \
        "{\"name\": \"${topic} Available /${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_available_${disk,,}\",${device}, \"value_template\": \"{{ value_json.available_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_use/config" -m \
        "{\"name\": \"${topic} Use% /${disk}\", \"unit_of_measurement\": \"%\",\"unique_id\":\"${topic}_use_${disk,,}\",${device}, \"value_template\": \"{{ value_json.use_${disk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        a=("${a[@]:1}")
    done
fi

while true; do
    # Create status message
    status="{\"1\":\"1\"";
    for disk in config addons ssl share backup media $moredisks
    do
    #    bashio::log.info "Inspecting ${disk}"
        mapfile -t fsdata < <(df /$disk)
        fsd=(${fsdata[1]})
        status="$status, \"size_${disk,,}\":\"${fsd[1]}\""
        status="$status, \"used_${disk,,}\":\"${fsd[2]}\""
        status="$status, \"available_${disk,,}\":\"${fsd[3]}\""
        status="$status, \"use_${disk,,}\":\"${fsd[4]%?}\""
    done
    status="$status}"
    # Send status message
    mosquitto_pub -t "homeassistant/sensor/${topic}/state" -m "$status"
    # Sleep
    sleep 60
done
