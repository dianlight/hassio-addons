 
#!/bin/bash

for addon in "$@"; do
    if [ -z ${TRAVIS_COMMIT_RANGE} ] || git diff --name-only ${TRAVIS_COMMIT_RANGE} | grep -v README.md | grep -q ${addon}; then
      echo $(pwd)/${addon}
      for arch in "_armhf" "armv7" "_amd64" "_aarch64" "_i386" ; do
       echo Target: ${arch}
       grep ${arch} $(pwd)/${addon}/config.json | grep "\"arch\":" >/dev/null && \
    		docker run --rm --privileged -v ~/.docker:/root/.docker -v $(pwd)/${addon}:/data homeassistant/amd64-builder --${arch} -t /data \
        || echo "Unsupported or Error!"
      done 
    else
    	echo "No change in commit range ${TRAVIS_COMMIT_RANGE}"
    fi
done
