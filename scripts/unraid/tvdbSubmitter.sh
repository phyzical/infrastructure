#!/bin/bash

source ./commonFuncs.sh

LOCKFILE="/tmp/tvdbsubmitter.lock"

trap 'failed_func $LOCKFILE "tvdbsubmitter Failed!!" "Youtube Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]
then
    echo "tvdbsubmitter running already."
    exit 1
else
    touch $LOCKFILE
    message="tvdbsubmitter Started"
    notify normal $message "tvdbsubmitter" $message
    docker run --rm -v /root/repos/infrastructure/scripts/unraid:/tmp/scripts \
    -v /mnt/user/Downloads/youtube:/tmp/episodes buildkite/puppeteer \
    node /tmp/scripts/tvdbSubmitter.js email="phyzicaly@hotmail.com" \
    username="phyzical" password="$1" renameOnly="false"
    
    echo "Finished tvdbsubmitter Download!!"
    rm -f $LOCKFILE
    notify normal "Finished tvdbsubmitter Download!!" "Finished tvdbsubmitter Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi