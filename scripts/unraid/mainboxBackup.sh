#!/bin/bash

source ./commonFuncs.sh

LOCKFILE="/tmp/backupInProgress.lock"

trap 'failed_func $LOCKFILE "Backup" "Backup Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]
then
    echo "backup running already."
    exit 1
else
    touch $LOCKFILE
    message="Backup Started"
    notify normal $message "Cronjob" $message
    declare -A backupFolders=(
        ["boot"]="/boot/"
        ["isos"]="/mnt/user/isos/"
        ["domains"]="/mnt/user/domains/"
        ["appdata"]="/mnt/user/appdata/"
    )
    toFolder="/mnt/user/Backup/"
    fromFolder="root@192.168.69.110"
    echo "Making $toFolder"
    mkdir -p "$toFolder"
    for folderKey in "${!backupFolders[@]}";
    do
        folder=${backupFolders[$folderKey]}
        echo "Rsyncing $fromFolder:$folder to $toFolder$folderKey"
        rsync -a "$fromFolder:$folder" "$toFolder$folderKey" --log-file="$toFolder/rsync-log.txt" --delete
    done
    echo "Finished Backing Up!!"
    rm -f $LOCKFILE
    notify normal "Finished Backing Up!!" "Finished Backing Up, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi
