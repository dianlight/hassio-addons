#!/bin/bash

echo "Example For local Build use"
echo "> check=no archs=--aarch64  ./build.sh sambanas"
echo "> if lock remove codenaotary from build.yaml and unset CAS_API_KEY"

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
  # Check id in addon there is config.yaml or config.json file
  if [ -f "${addon}/config.yaml" ]; then
    echo "Found config.yaml for ${addon}"
    config="${addon}/config.yaml"
    qv="yq"
  elif [ -f "${addon}/config.json" ]; then
    echo "Found config.json for ${addon}"
    config="${addon}/config.json"
    qv="jq"
  else
    echo "No config file found for ${addon}"
    exit
  fi

  if [[ "$(${qv} -r '.image' ${config})" == 'null' ]]; then
    echo "${ANSI_YELLOW}No build image set for ${addon}. Skip build!${ANSI_CLEAR}"
    exit 0
  fi

  env | grep -v -E "HOME|TERM|PWD|HOSTNAME|PATH|SHLVL|USER|GOROOT" >"./env_file"

  if [[ "${check}x" == "x" ]]; then
    check=--docker-hub-check
  else
    check="--version latest --release latest --release-tag"
  fi

  if [[ "${archs}x" == "x" ]]; then
    archs=$(${qv} -r '.arch // ["armv7", "armhf", "amd64", "aarch64", "i386"] | [.[] | "--" + .] | join(" ")' ${config})
  fi
  echo "${ANSI_GREEN}Building ${addon} -> ${archs} ${ANSI_CLEAR}"

  # Momentary fix because CAS service don't respose. So no sign in local.
  unset CAS_API_KEY

  ## Snapshot Different Projects Enrichment
  ### Sambanas SRAT
  #if [[ "${addon}" == "sambanas" ]]; then
  #  cp -rv ../Sources/srat/backend/dist/* sambanas/rootfs/usr/local/bin
  #fi
  ## END

  hadolint -c $(pwd)/${addon}/.hadolint.yaml $(pwd)/${addon}/Dockerfile &&
    docker run --rm --privileged -v ~/.docker:/root/.docker_o -v $(pwd)/${addon}:/data --env-file "./env_file" ghcr.io/home-assistant/${arch}-builder:latest \
      --docker-hub dianlight --docker-user ${DOCKER_USERNAME} --docker-password ${DOCKER_TOKEN} ${check} ${archs} -t /data
  #--cosign
done
