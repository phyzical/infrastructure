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
  password="$1"
  shift
  fromFolder="$1"
  shift
  dryRun="$1"
  shift
  backupFolders=("$@")
  echo "Making $toFolder"
  mkdir -p "$toFolder"
  for folder in "${backupFolders[@]}"; do
    folderKey="${folder//\/mnt\/user\//}"
    echo "Rsyncing $fromFolder:$folder to $toFolder$folderKey"
    fullToFolder="$toFolder$folderKey"
    mkdir -p "$fullToFolder"
    dryRunFlag=""
    if [ "$dryRun" == "true" ]; then
      dryRunFlag="--dry-run"
    fi
    rsync -a --rsh="/usr/bin/sshpass -p $password ssh -o StrictHostKeyChecking=no -l root" --progress $dryRunFlag --info=progress2 "$fromFolder:$folder" "$fullToFolder" --log-file="$toFolder/rsync-log.txt" --delete
  done
  echo "Finished Backing Up!!"
  rm -f $LOCKFILE
  notify normal "Finished Backing Up!!" "Finished Backing Up, it took $(elapsed_time_message $SECONDS)" ""
  exit 0
fi
