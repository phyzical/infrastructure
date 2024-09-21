#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$DIR"/commonFuncs.sh

LOCKFILE="/tmp/medalInProgress.lock"

trap 'failed_func $LOCKFILE "Medal Failed!! with code ($?)" "Medal Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]; then
  echo "Medal running already."
  exit 1
else
  touch $LOCKFILE
  message="Medal Started"
  notify normal "$message" "Medal" "$message"
  dockerImage="ghcr.io/phyzical/medal.tv-bulk-downloader"
  docker pull $dockerImage
  docker run --rm \
    -v /mnt/user/Downloads/medal/config.json:/app/config.json \
    -v /mnt/user/Downloads/medal:/downloads \
    $dockerImage:latest

  echo "Finished Medal Download!!"
  rm -f $LOCKFILE
  notify normal "Finished Medal Download!!" "Finished Medal Download, it took $(elapsed_time_message $SECONDS)" ""
  exit 0
fi
