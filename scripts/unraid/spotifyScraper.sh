#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

LOCKFILE="/tmp/spotifyInProgress.lock"
trap 'failed_func $LOCKFILE "Spotify Failed!!" "Spotify Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]
then
    echo "Spotify running already."
    exit 1
else
    touch $LOCKFILE
    message="Spotify Started"
    notify normal $message "Spotify" $message
    spotifyPath="/mnt/user/Downloads/spotify"
    dockerImage="phyzical/spotify-dl"
    docker pull $dockerImage
    for sourceKey in "${!sources[@]}";
    do
        source=${sources[$sourceKey]}
        echo "Downloading $source"
        docker run -u $(id -u):$(id -g) -v $spotifyPath:/download:rw --rm phyzical/spotify-dl \
        --u $username --p $password --cf "/download/songs.txt" $source
    done
    
    echo "Finished Spotify Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Spotify Download!!" "Finished Spotify Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

