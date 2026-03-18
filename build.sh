#!/bin/bash

echo "Example For local Build use"
echo "> archs=aarch64 ./build.sh sambanas"
echo "> archs can be a space-separated list: archs='aarch64 amd64'"

# Check for arch
arch=$(arch)
# use aarch64 on Apple M1
if [[ "$(uname)x" == "Darwinx" && "${arch}x" == "arm64x" ]]; then
  echo "MacOS on Apple M1 Detected!"
  arch="aarch64"
elif [[ "${arch}x" == "x86_64x" ]]; then
  arch="amd64"
fi

echo "Running for arch ${arch} and '$@'"

# Map HA addon arch names to Docker platform strings
arch_to_platform() {
  case "$1" in
    amd64)   echo "linux/amd64" ;;
    aarch64) echo "linux/arm64" ;;
    armv7)   echo "linux/arm/v7" ;;
    armhf)   echo "linux/arm/v6" ;;
    i386)    echo "linux/386" ;;
    *)       echo "linux/$1" ;;
  esac
}

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

  VERSION=$(${qv} -r '.version' ${config})
  ADDON_NAME=$(${qv} -r '.name' ${config})
  ADDON_DESCRIPTION=$(${qv} -r '.description' ${config})
  BUILD_DATE=$(date --rfc-3339=seconds --utc)
  BUILD_REF=$(git rev-parse HEAD 2>/dev/null || echo 'local')
  BUILD_REPOSITORY=${GITHUB_REPOSITORY:-dianlight/hassio-addons}

  if [[ "${archs}x" == "x" ]]; then
    archs_list=$(${qv} -r '.arch // ["armv7", "armhf", "amd64", "aarch64", "i386"] | .[]' ${config})
  else
    # Support both --aarch64 style (legacy) and plain aarch64 style
    archs_list=$(echo "${archs}" | tr ' ' '\n' | sed 's/^--//')
  fi

  echo "${ANSI_GREEN}Building ${addon} -> ${archs_list} ${ANSI_CLEAR}"

  # Login to Docker Hub if credentials are available
  if [[ -n "${DOCKER_TOKEN}" && -n "${DOCKER_USERNAME}" ]]; then
    echo "${DOCKER_TOKEN}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  fi

  # Ensure buildx builder is available
  docker buildx inspect hassio-builder 2>/dev/null || docker buildx create --name hassio-builder --use
  docker buildx use hassio-builder

  hadolint -c $(pwd)/${addon}/.hadolint.yaml $(pwd)/${addon}/Dockerfile || exit 1

  for each_arch in ${archs_list}; do
    PLATFORM=$(arch_to_platform "${each_arch}")
    IMAGE_NAME="${DOCKER_USERNAME:-dianlight}/${each_arch}-addon-${addon}"

    BUILD_FROM=""
    if [ -f "${addon}/build.yaml" ]; then
      BUILD_FROM=$(yq -r ".build_from.${each_arch}" ${addon}/build.yaml)
      if [[ "${BUILD_FROM}" == "null" ]]; then
        BUILD_FROM=""
      fi
    fi

    echo "${ANSI_GREEN}Building ${IMAGE_NAME} for platform ${PLATFORM}${ANSI_CLEAR}"

    push_flag=""
    if [[ -n "${DOCKER_TOKEN}" && -n "${DOCKER_USERNAME}" ]]; then
      push_flag="--push"
    else
      push_flag="--load"
    fi

    docker buildx build \
      --platform "${PLATFORM}" \
      --build-arg BUILD_ARCH="${each_arch}" \
      --build-arg BUILD_VERSION="${VERSION}" \
      ${BUILD_FROM:+--build-arg BUILD_FROM="${BUILD_FROM}"} \
      --build-arg BUILD_NAME="${ADDON_NAME}" \
      --build-arg BUILD_DESCRIPTION="${ADDON_DESCRIPTION}" \
      --build-arg BUILD_REF="${BUILD_REF}" \
      --build-arg BUILD_DATE="${BUILD_DATE}" \
      --build-arg BUILD_REPOSITORY="${BUILD_REPOSITORY}" \
      --tag "${IMAGE_NAME}:${VERSION}" \
      --tag "${IMAGE_NAME}:latest" \
      ${push_flag} \
      ${addon}
  done
done
