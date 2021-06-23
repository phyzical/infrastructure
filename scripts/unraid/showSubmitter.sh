#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

LOCKFILE="/tmp/tvdbsubmitter.lock"

trap 'failed_func $LOCKFILE "tvdbsubmitter Failed!!" "Youtube Failed!! on line $LINENO"' ERR SIGTERM

username=$1
password=$2
email=$3
youtubeFolder=$4
renameOnly=$5

if [ -e $LOCKFILE ]
then
    echo "tvdbsubmitter running already."
    exit 1
else
    touch $LOCKFILE
    message="tvdbsubmitter Started"
    notify normal $message "tvdbsubmitter" $message
    docker run --rm -u 99:100 -v $DIR/showSubmitter:/tmp/scripts \
    -v "$youtubeFolder":/tmp/episodes buildkite/puppeteer \
    node /tmp/scripts/main.js email="$email" \
    username="$username" password="$password" renameOnly="$renameOnly"

   chmod_unraid_file_permissions $youtubeFolder

    
    echo "Finished tvdbsubmitter Download!!"
    rm -f $LOCKFILE
    notify normal "Finished tvdbsubmitter Download!!" "Finished tvdbsubmitter Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi
