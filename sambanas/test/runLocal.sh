#! /bin/bash
mkdir -p /tmp/my_test_data
cp options.json /tmp/my_test_data
docker build --build-arg BUILD_FROM="homeassistant/aarch64-base:latest" -t danveitch76/aarch64-addon-sambanas ..
docker run --rm -v /tmp/my_test_data:/data -p 5300 danveitch76/aarch64-addon-sambanas
