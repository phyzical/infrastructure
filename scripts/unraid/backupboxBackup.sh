#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

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
        ["appdata"]="/mnt/user/appdata/"
        ["Tv Shows - moviedb"]="/mnt/user/Media/Tv\ Shows\ -\ moviedb/"
        ["Cartoons"]="/mnt/user/Media/Cartoons/"
        ["Documentaires"]="/mnt/user/Media/Documentaires/"
        ["Movies"]="/mnt/user/Media/Movies/"
        ["Tv Shows"]="/mnt/user/Media/Tv\ Shows/"
        ["files"]="/mnt/user/files/"
        ["domains"]="/mnt/user/domains/"
    )
    toFolder="/mnt/user/Backup/"
    fromFolder="root@192.168.69.111"
    echo "Making $toFolder"
    mkdir -p "$toFolder"
    for folderKey in "${!backupFolders[@]}";
    do
        folder=${backupFolders[$folderKey]}
        echo "Rsyncing $fromFolder:$folder to $toFolder$folderKey"
        rsync -a "$fromFolder:$folder" "$toFolder$folderKey" --exclude="nzbdrone.db" --log-file="$toFolder/rsync-log.txt" --delete
    done
    echo "Finished Backing Up!!"
    rm -f $LOCKFILE
    notify normal "Finished Backing Up!!" "Finished Backing Up, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi



