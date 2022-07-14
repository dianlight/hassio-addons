#!/usr/bin/env bashio
declare topic
declare moredisks
declare status
declare fsdata

topic=$(bashio::config 'mqtt_topic');if [ "$topic" = "null" ]; then topic="sambanas"; fi;

# Home assistant auto discovery    
if [ -f /root/.config/mosquitto_pub ] && ! bashio::config.true "autodiscovery.disable_discovery"; then
    a=({a..z})
    if ! bashio::config.true "autodiscovery.disable_persistent"; then prs="-r";fi
    bashio::log.info "Sending MQTT autodiscovery..."
    device="\"device\":{\"identifiers\":[\"${topic}\"],\"name\": \"Samba Nas Sensors\", \"model\": \"Samba $(smbd -V)\", \"manufacturer\": \"@Dianlight\"},\"icon\":\"mdi:harddisk\"" 
    for disk in $(awk '/^   path = .*/g { print $3 }' /etc/samba/smb.conf) 
    do
        ldisk=${disk##*/}
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_size/config" -m \
        "{\"name\": \"${topic} Size ${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_size_${ldisk,,}\",${device},\"value_template\": \"{{ value_json.size_${ldisk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_used/config" -m \
        "{\"name\": \"${topic} Used ${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_used_${ldisk,,}\",${device}, \"value_template\": \"{{ value_json.used_${ldisk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_available/config" -m \
        "{\"name\": \"${topic} Available ${disk}\", \"unit_of_measurement\": \"Kb\",\"unique_id\":\"${topic}_available_${ldisk,,}\",${device}, \"value_template\": \"{{ value_json.available_${ldisk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        mosquitto_pub ${prs} -t "homeassistant/sensor/${topic}/${a}_use/config" -m \
        "{\"name\": \"${topic} Use% ${disk}\", \"unit_of_measurement\": \"%\",\"unique_id\":\"${topic}_use_${ldisk,,}\",${device}, \"value_template\": \"{{ value_json.use_${ldisk,,}}}\", \"state_topic\": \"homeassistant/sensor/${topic}/state\"}"
        a=("${a[@]:1}")
    done
fi

while true; do
    # Create status message
    status="{\"1\":\"1\"";
    for disk in $(awk '/^   path = .*/g { print $3 }' /etc/samba/smb.conf)
    do
        ldisk=${disk##*/}
        mapfile -t fsdata < <(df $disk)
        fsd=(${fsdata[1]})
        status="$status, \"size_${ldisk,,}\":\"${fsd[1]}\""
        status="$status, \"used_${ldisk,,}\":\"${fsd[2]}\""
        status="$status, \"available_${ldisk,,}\":\"${fsd[3]}\""
        status="$status, \"use_${ldisk,,}\":\"${fsd[4]%?}\""
    done    
    status="$status}"
    # Send status message
    mosquitto_pub -t "homeassistant/sensor/${topic}/state" -m "$status"
    # Sleep
    sleep 60
done
