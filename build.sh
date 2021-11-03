#!/bin/bash

# Check for arch
arch=$(arch)
# use aarch64 on Apple M1
if [[ "$(uname)x" == "Darwinx" && "${arch}x" == "arm64x" ]]; then
  echo "MacOS on Apple M1 Detected!"
  arch="aarch64"
elif [[ "${arch}x" == "x86_64x" ]]; then
  arch="amd64"  
fi

echo "Running for arch ${arch}"

for addon in "$@"; do

    if [[ "$(jq -r '.image' ${addon}/config.json)" == 'null' ]]; then
      echo "${ANSI_YELLOW}No build image set for ${addon}. Skip build!${ANSI_CLEAR}"
      exit 0
    fi

    if [[ "${check}x" == "x" ]];then
      check=--docker-hub-check
    else 
      check=""   
    fi

    if [[ "${archs}x" == "x" ]];then
      archs=$(jq -r '.arch // ["armv7", "armhf", "amd64", "aarch64", "i386"] | [.[] | "--" + .] | join(" ")' ${addon}/config.json)
    fi
    echo "${ANSI_GREEN}Building ${addon} -> ${archs} ${ANSI_CLEAR}"
    docker run  --rm --privileged -v ~/.docker:/root/.docker -v $(pwd)/${addon}:/data homeassistant/${arch}-builder  --docker-hub dianlight ${check} ${archs} -t /data 
done