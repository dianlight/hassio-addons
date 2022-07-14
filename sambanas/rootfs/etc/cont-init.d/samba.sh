#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the Samba service for running
# ==============================================================================
declare password
declare username
declare -a interfaces=()
export HOSTNAME

# Check Login data
if ! bashio::config.has_value 'username' || ! bashio::config.has_value 'password'; then
    bashio::exit.nok "Setting a username and password is required!"
fi

# Read hostname from API or setting default "hassio"
HOSTNAME=$(bashio::info.hostname)
if bashio::var.is_empty "${HOSTNAME}"; then
    bashio::log.warning "Can't read hostname, using default."
    name="hassio"
    HOSTNAME="hassio"
fi
bashio::log.info "Hostname: ${HOSTNAME}"

if bashio::config.has_value 'interfaces'; then
    bashio::log.info "Interfaces from config: $(bashio::config 'interfaces')"
    for interface in $(bashio::config 'interfaces'); do
        if [ -d "/sys/class/net/${interface}" ]; then
            interfaces+=("${interface}")
        else
            bashio::log.warning "Interface ${interface} not found, skipping."
        fi
    done   
else
    # Get supported interfaces
    for interface in $(bashio::network.interfaces); do
        interfaces+=("${interface}")
    done
fi

if [ ${#interfaces[@]} -eq 0 ]; then
    bashio::exit.nok 'No supported interfaces found to bind on.'
fi
bashio::log.info "Interfaces: $(printf '%s ' "${interfaces[@]}")"


# Generate Samba configuration.
touch /tmp/local_mount
jq ".interfaces = $(jq -c -n '$ARGS.positional' --args -- "${interfaces[@]}") | .moredisks = $(jq -R -s -c 'split("\n") | map(select(length > 0)) | [ .[] | ltrimstr("/") ]' < /tmp/local_mount) " /data/options.json \
    | tempio \
      -template /usr/share/tempio/smb.gtpl \
      -out /etc/samba/smb.conf

# Only for Debug
#bashio::log.info "Dump SMB configuration:"
#cat /etc/samba/smb.conf >&2


# Init user
username=$(bashio::config 'username')
password=$(bashio::config 'password')
addgroup "${username}"
adduser -D -H -G "${username}" -s /bin/false "${username}"
# shellcheck disable=SC1117
echo -e "${password}\n${password}" \
    | smbpasswd -a -s -c "/etc/samba/smb.conf" "${username}"

# Create other users
for user in $(bashio::config 'other_users'); do
    username=$(echo ${user} | jq -r '.username')
    password=$(echo ${user} | jq -r '.password')
   # bashio::log.info "Creating user ${username}"
    addgroup "${username}"
    adduser -D -H -G "${username}" -s /bin/false "${username}"
    # shellcheck disable=SC1117
    echo -e "${password}\n${password}" \
        | smbpasswd -a -s -c "/etc/samba/smb.conf" "${username}"
done

# Log exposed mounted shares
bashio::log.info "Exposed Disks Summary: $(< /etc/samba/smb.conf grep path | tr -d '\n')"
