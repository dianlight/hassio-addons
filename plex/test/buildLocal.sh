#! /bin/bash
# onetime when docker upgrade 
# docker run --rm --privileged multiarch/qemu-user-static:register
docker build --build-arg BUILD_FROM="hassioaddons/ubuntu-base-armv7:5.2.1" --build-arg BUILD_ARCH="armv7" -t dianlight/armv7-addon-plex ../../addon-plex/plex
docker push dianlight/armv7-addon-plex:latest