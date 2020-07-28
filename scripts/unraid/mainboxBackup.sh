#!/bin/bash

failed () {
    rm -f /tmp/backupInProgress.lock
    message="Backup Failed!!"
    /usr/local/emhttp/webGui/scripts/notify -i alert -s "$message" -e "Cronjob" -d "$message on line $1"
    exit 0
}

trap 'failed $LINENO' ERR

if [ -e /tmp/backupInProgress.lock ]
then
    echo "backup running already."
    exit 1
else
    touch /tmp/backupInProgress.lock
    message="Backup Started"
    /usr/local/emhttp/webGui/scripts/notify -i normal -s  "$message" -e "Cronjob" -d "$message"
    declare -A backupFolders=(["boot"]="/boot/"
                ["isos"]="/mnt/user/isos/" 
                ["domains"]="/mnt/user/domains/"
                ["appdata"]="/mnt/user/appdata/")
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
    rm -f /tmp/backupInProgress.lock
    ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
    /usr/local/emhttp/webGui/scripts/notify -i normal -s "Finished Backing Up!!" -e "Finished Backing Up, it took $ELAPSED"
    exit 0
fi
