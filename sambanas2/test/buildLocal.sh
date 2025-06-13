#! /bin/bash
# onetime when docker upgrade 
#docker run --rm --privileged multiarch/qemu-user-static:register
docker build --build-arg BUILD_FROM="homeassistant/armv7-base:3.13" --build-arg CLI_VERSION="4.13.0" --build-arg BUILD_ARCH="armv7" -t dianlight/armv7-addon-sambanas .. && \
docker push dianlight/armv7-addon-sambanas:latest