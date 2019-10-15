 
#!/bin/bash -X

for addon in "$@"; do
    if [ -z ${TRAVIS_COMMIT_RANGE} ] || git diff --name-only ${TRAVIS_COMMIT_RANGE} | grep -v README.md | grep -q ${addon}; then
		docker run --rm --privileged -v ~/.docker:/root/.docker -v $(pwd)/${addon}:/data homeassistant/amd64-builder --all -t /data
    else
	echo "No change in commit range ${TRAVIS_COMMIT_RANGE}"
    fi
done
