#!/bin/bash
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")/../.." && pwd)/sambanas2"
BUILD_ARCH="${BUILD_ARCH:-amd64}"
BUILD_FROM="${BUILD_FROM:-ghcr.io/hassio-addons/base:20.1.0}"

case "${BUILD_ARCH}" in
  aarch64) PLATFORM="linux/arm64" ;;
  *)       PLATFORM="linux/${BUILD_ARCH}" ;;
esac

IMAGE_TAG="ghcr.io/dianlight/addon-sambanas2:local-${BUILD_ARCH}"

echo "Building sambanas2 [${BUILD_ARCH} / ${PLATFORM}]..."
docker buildx build \
  --platform "${PLATFORM}" \
  --build-arg "BUILD_FROM=${BUILD_FROM}" \
  --build-arg "BUILD_ARCH=${BUILD_ARCH}" \
  --build-arg "HA_CLI_VERSION=${HA_CLI_VERSION:-5.0.0}" \
  --build-arg "SRAT_VERSION=${SRAT_VERSION:-2026.4.0-rc2}" \
  --build-arg "SAMBA_VERSION=${SAMBA_VERSION:-distribution}" \
  --tag "${IMAGE_TAG}" \
  --load \
  "${ADDON_DIR}"

echo "Built: ${IMAGE_TAG}"
