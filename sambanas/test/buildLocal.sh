#! /bin/bash
# onetime when docker upgrade 
#docker run --rm --privileged multiarch/qemu-user-static:register
docker build --build-arg BUILD_FROM="homeassistant/aarch64-base:3.13" --build-arg CLI_VERSION="4.13.0" --build-arg BUILD_ARCH="aarch64" -t danveitch76/aarch64-addon-sambanas .. && \
docker push danveitch76/aarch64-addon-sambanas:latest