#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$DIR"/commonFuncs.sh

LOCKFILE="/tmp/backupInProgress.lock"

trap 'failed_func $LOCKFILE "Backup" "Backup Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]; then
  echo "backup running already."
  exit 1
else
  touch $LOCKFILE
  message="Backup Started"
  notify normal "$message" "Cronjob" "$message"
  toFolder="/mnt/user/Backup/"
  fromFolder="$1"
  shift
  backupFolders=("$@")
  echo "Making $toFolder"
  mkdir -p "$toFolder"
  for folder in "${backupFolders[@]}"; do
    folderKey="${folder//\/mnt\/user\//}"
    echo "Rsyncing $fromFolder:$folder to $toFolder$folderKey"
    fullToFolder="$toFolder$folderKey"
    mkdir -p "$fullToFolder"
    rsync -a --progress --info=progress2 "$fromFolder:$folder" "$fullToFolder" --log-file="$toFolder/rsync-log.txt" --delete
  done
  echo "Finished Backing Up!!"
  rm -f $LOCKFILE
  notify normal "Finished Backing Up!!" "Finished Backing Up, it took $(elapsed_time_message $SECONDS)" ""
  exit 0
fi
