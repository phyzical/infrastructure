#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
shopt -s extglob

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
      erroredFolders=($(find "$downloadFolder" -type d -name 'errored' | sed -e 's/ /\~_-/g'))
      for folder in $erroredFolders
      do
        folder=$(echo "$folder" | sed -e 's/\~_-/ /g')  
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
      manualFolders=($(find $downloadFolder -type d))
      for folder in "${manualFolders[@]}"
      do
        move_episodes_to_season_folders "$folder" "$folder" "$nonSeasonFolders"
      done
    fi

    docker run --rm -u 99:100 -v $DIR/showSubmitter:/tmp/scripts \
    -v "$youtubeFolder":/tmp/episodes buildkite/puppeteer \
    node /tmp/scripts/main.js email="$email" \
    username="$username" password="$password" renameOnly="$renameOnly"

    chmod_unraid_file_permissions $youtubeFolder

    destinationFolder="/mnt/user/Media/Youtube/"
    showFolders=($(find "$downloadFolder" -type d -maxdepth 1 -mindepth 1 | sed -e 's/ /\~_-/g'))
    for show in ${showFolders[@]}
    do
      show=$(echo "$show" | sed -e 's/\~_-/ /g')  
      showName=$(basename "$show")
      seasonFolders=($(find "$show" -type d -maxdepth 1 -mindepth 1 | sed -e 's/ /\~_-/g'))
      for season in ${seasonFolders[@]}
      do
        season=$(echo "$season" | sed -e 's/\~_-/ /g')  
        seasonName=$(basename "$season")
        finalDestination=$(echo "${destinationFolder}${showName}/${seasonName}" | sed -e's/-/\ /g')
        anyFiles=$(find "$season" -type f  -not -path "*errored/*" )
        if [ "$anyFiles" != "" ]; then
          echo "Trying to move $season to ${finalDestination}"
          mkdir -p "$finalDestination" && mv "$season"/!(errored) "$finalDestination/"
        fi
      done
    done
    remove_empty_folders "$downloadFolder"

    echo "Finished tvdbsubmitter Download!!"
    rm -f $LOCKFILE
    notify normal "Finished tvdbsubmitter Download!!" "Finished tvdbsubmitter Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi
