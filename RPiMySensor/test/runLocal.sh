#! /bin/bash
mkdir -p /tmp/my_test_data
cp options.json /tmp/my_test_data
docker run --rm -v /tmp/my_test_data:/data -p 5300 local/my-test-addon
