#!/bin/bash
if [[ $# -eq 0 ]]; then
    echo 'Use $0 <hexmessage> <ipdestination>'
    exit 0
fi

echo -e $1 | xxd -r -p | nc -v -u -w 3 $2 6199
