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
retryFailedEpisodes=$6
handleManualShows=$7

downloadFolder="/mnt/user/Downloads/youtube/"
if [ -e $LOCKFILE ]
then
    echo "tvdbsubmitter running already."
    exit 1
else
    touch $LOCKFILE
    message="tvdbsubmitter Started"
    notify normal $message "tvdbsubmitter" $message

    if [ "$retryFailedEpisodes" == "true" ]; then
      find $downloadFolder -type d -name 'errored' -print0 | while read -d $'\0' folder
      do
        cd "$folder/.."
        mv */* .
        rmdir "$folder"
      done
    fi

    if [ "$handleManualShows" == "true" ]; then
      renameOnly=true
      nonSeasonFolders=(
        "$downloadFolderSmarter-Every-Day"
      )
      find $downloadFolder -type d -print0 | while read -d $'\0' folder
      do    
        move_episodes_to_season_folders "$folder" "$folder" "$nonSeasonFolders"
      done
    fi

    docker run --rm -u 99:100 -v $DIR/showSubmitter:/tmp/scripts \
    -v "$youtubeFolder":/tmp/episodes buildkite/puppeteer \
    node /tmp/scripts/main.js email="$email" \
    username="$username" password="$password" renameOnly="$renameOnly"

    chmod_unraid_file_permissions $youtubeFolder

    ## todo move finished downloads into the correct destination folder? proably need a seperate folder to make easier
    ## for each show
    ## for each season
    ## move episodes into the correct show season folder
    # find $downloadFolder -type d -print0 | while read -d $'\0' folder
    # do
    #   echo "Trying to remove $folder if empty"
    #   find $folder -type d -empty -delete
    # done
    remove_empty_folders "$downloadFolder"

    echo "Finished tvdbsubmitter Download!!"
    rm -f $LOCKFILE
    notify normal "Finished tvdbsubmitter Download!!" "Finished tvdbsubmitter Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi
