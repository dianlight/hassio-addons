 
#!/bin/bash
# use aarch64 on M1

for addon in "$@"; do

    if [[ "$(jq -r '.image' ${addon}/config.json)" == 'null' ]]; then
      echo "${ANSI_YELLOW}No build image set for ${addon}. Skip build!${ANSI_CLEAR}"
      exit 0
    fi

    archs=$(jq -r '.arch // ["armv7", "armhf", "amd64", "aarch64", "i386"] | [.[] | "--" + .] | join(" ")' ${addon}/config.json)
    echo "${ANSI_GREEN}Building ${addon} -> ${archs} ${ANSI_CLEAR}"
#    docker run  --rm --privileged -v ~/.docker:/root/.docker -v $(pwd)/${addon}:/data homeassistant/amd64-builder --docker-hub-check --${arch} -t /data 
    docker run  --rm --privileged -v ~/.docker:/root/.docker -v '/var/run/docker.sock:/var/run/docker.sock' -v $(pwd)/${addon}:/data homeassistant/amd64-builder --docker-hub-check ${archs} -t /data 
done