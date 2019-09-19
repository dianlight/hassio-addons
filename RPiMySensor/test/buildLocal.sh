#! /bin/bash

docker build --build-arg BUILD_FROM="homeassistant/amd64-base:latest" -t local/my-test-addon ..