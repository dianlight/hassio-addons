#!/usr/bin/env bashio
set +u
#set -x

LOGGING=$(bashio::info 'hassio.info.logging' '.logging')

MYSGW_FLAGS="--bin-dir=/data/bin --my-transport=rf24 --my-gateway=ethernet --my-port=5003 --my-config-file=/etc/mysensors.conf --no_init_system" 
if bashio::config.has_value 'channel'; then
     MYSGW_FLAGS="$MYSGW_FLAGS --my-rf24-channel=$(bashio::config 'channel')"
fi 
if bashio::config.has_value 'pa_level'; then
     MYSGW_FLAGS="$MYSGW_FLAGS --my-rf24-pa-level=$(bashio::config 'pa_level')"
fi 
if bashio::config.has_value 'ce_pin'; then
     MYSGW_FLAGS="$MYSGW_FLAGS --my-rf24-ce-pin=$(bashio::config 'ce_pin')"
fi 
if bashio::config.has_value 'cs_pin'; then
     MYSGW_FLAGS="$MYSGW_FLAGS --my-rf24-cs-pin=$(bashio::config 'cs_pin')"
fi 
if ! bashio::config.is_empty 'security'; then
    bashio::log.warn \
		"FOUND Security config (NOT YET IMPLEMENTED)!"
fi
if ! bashio::config.is_empty 'use_irq'; then
    bashio::log.info \
		"Use IRQ Pin"
    if bashio::config.has_value 'use_irq.rx_buffer'; then
        MYSGW_FLAGS="$MYSGW_FLAGS --my-rx-message-buffer-size=$(bashio::config 'use_irq.rx_buffer')"
    fi 
    if bashio::config.has_value 'use_irq.pin'; then
        MYSGW_FLAGS="$MYSGW_FLAGS --my-rf24-irq-pin=$(bashio::config 'use_irq.pin')"
    fi 
fi
if ! bashio::config.is_empty 'use_led'; then
    bashio::log.info \
		"Use LED Monitor"
    if bashio::config.has_value 'use_led.err_pin'; then
        MYSGW_FLAGS="$MYSGW_FLAGS --my-leds-err-pin=$(bashio::config 'use_led.err_pin')"
    fi 
    if bashio::config.has_value 'use_led.rx_pin'; then
        MYSGW_FLAGS="$MYSGW_FLAGS --my-leds-rx-pin=$(bashio::config 'use_led.rx_pin')"
    fi 
    if bashio::config.has_value 'use_led.tx_pin'; then
        MYSGW_FLAGS="$MYSGW_FLAGS --my-leds-tx-pin=$(bashio::config 'use_led.tx_pin')"
    fi 
fi
if bashio::config.false 'rebuild'; then
    MYSGW_FLAGS="$MYSGW_FLAGS --no-clean"
fi


bashio::log.debug "${MYSGW_FLAGS}"


# MySensors.conf customizations
if bashio::config.has_value 'log_level'; then
     sed -i "s/verbose=.*/verbose=$(bashio::config 'log_level')/g" /etc/mysensors.conf
fi 

# Test SPI Device
pwd
/spidev_test -D /dev/spidev0.0

cd /MySensors 
if echo $MYSGW_FLAGS | md5sum -c /data/mysensors.config.md5; then
    #OLD CONFIG SAME AS NEW
    bashio::log.debug "Old config found. Skipping compilation...."
    # See https://www.mysensors.org/build/raspberry
    /data/bin/mysgw 
else
    #NEW CONFIG
    #Salvataggio config
    echo $MYSGW_FLAGS | md5sum - > /data/mysensors.config.md5
    # See https://www.mysensors.org/build/raspberry
    ./configure $MYSGW_FLAGS && make && /data/bin/mysgw 
fi  
 

##WebServerUI
#python3 -m http.server 8000