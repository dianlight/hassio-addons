#!/bin/bash
set -euo pipefail

(( BASH_VERSINFO[0] >= 4 )) || { echo "Error: bash 4+ required (macOS: brew install bash)" >&2; exit 1; }

echo "Example for local build:"
echo "  check=no archs='aarch64' ./build.sh sambanas2"
echo "  push=yes ./build.sh sambanas2   # push to GHCR after build"

# Detect host arch
host_arch=$(uname -m)
if [[ "$(uname)" == "Darwin" && "${host_arch}" == "arm64" ]]; then
  echo "MacOS on Apple M1 Detected!"
  default_arch="aarch64"
elif [[ "${host_arch}" == "x86_64" ]]; then
  default_arch="amd64"
else
  default_arch="amd64"
fi

echo "Default arch: ${default_arch}"

# Map HA arch name to Docker platform string
arch_to_platform() {
  case "$1" in
    aarch64) echo "linux/arm64" ;;
    amd64)   echo "linux/amd64" ;;
    *)       echo "linux/$1" ;;
  esac
}

# Ensure a buildx builder with multi-arch (QEMU) support exists
setup_buildx() {
  if ! docker buildx inspect multiarch-builder &>/dev/null; then
    echo "Creating multiarch buildx builder..."
    docker buildx create --name multiarch-builder --driver docker-container \
      --use --bootstrap
  else
    docker buildx use multiarch-builder
  fi
}

for addon in "$@"; do
  # Locate config file
  if [[ -f "${addon}/config.yaml" ]]; then
    config="${addon}/config.yaml"
    qv="yq"
  elif [[ -f "${addon}/config.json" ]]; then
    config="${addon}/config.json"
    qv="jq"
  else
    echo "No config file found for ${addon}" >&2
    exit 1
  fi

  # Skip addons without an image field
  image_val=$("${qv}" -r '.image' "${config}")
  if [[ "${image_val}" == "null" || -z "${image_val}" ]]; then
    echo "No build image set for ${addon}. Skipping."
    continue
  fi

  # Lint Dockerfile unless check=no
  if [[ "${check:-}" != "no" ]]; then
    echo "Linting ${addon}/Dockerfile..."
    hadolint -c "$(pwd)/${addon}/.hadolint.yaml" "$(pwd)/${addon}/Dockerfile"
  fi

  # Determine target architectures
  # Accepts: archs="amd64 aarch64" or archs="--amd64 --aarch64" (legacy compat)
  if [[ -z "${archs:-}" ]]; then
    mapfile -t build_archs < <("${qv}" -r '.arch[]' "${config}" | grep -E 'amd64|aarch64')
    if [[ ${#build_archs[@]} -eq 0 ]]; then
      build_archs=("${default_arch}")
    fi
  else
    build_archs=()
    for a in ${archs}; do
      build_archs+=("${a#--}")
    done
  fi

  setup_buildx

  for arch in "${build_archs[@]}"; do
    platform=$(arch_to_platform "${arch}")

    # If build.yaml is present (legacy), read per-arch BUILD_FROM; otherwise Dockerfile default applies
    build_from_arg=""
    if [[ -f "${addon}/build.yaml" ]]; then
      bf=$(yq e ".build_from.${arch}" "${addon}/build.yaml" 2>/dev/null || true)
      if [[ -n "${bf}" && "${bf}" != "null" ]]; then
        build_from_arg="--build-arg BUILD_FROM=${bf}"
      fi
    fi

    # Derive image name from config.yaml image field (strip registry prefix and arch segment)
    image_name=$(echo "${image_val}" | sed 's|.*/||; s|{arch}-||')
    image_tag="ghcr.io/dianlight/${image_name}:local-${arch}"

    push_flag="--load"
    if [[ "${push:-}" == "yes" ]]; then
      push_flag="--push"
    fi

    echo "Building ${addon} [${arch} / ${platform}]..."
    # shellcheck disable=SC2086
    docker buildx build \
      --platform "${platform}" \
      --build-arg "BUILD_ARCH=${arch}" \
      ${build_from_arg} \
      --tag "${image_tag}" \
      ${push_flag} \
      "${addon}"

    echo "Done: ${image_tag}"
  done
done
