#!/bin/bash
set -euo pipefail

BUILD_ARCH="${BUILD_ARCH:-amd64}"
IMAGE_TAG="ghcr.io/dianlight/addon-sambanas2:local-${BUILD_ARCH}"

mkdir -p /tmp/my_test_data
cp "$(dirname "$0")/options.json" /tmp/my_test_data

docker run --rm -v /tmp/my_test_data:/data -p 5300 "${IMAGE_TAG}"
