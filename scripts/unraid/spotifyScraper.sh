#!/bin/bash
## This uses the following repository https://github.com/SwapnilSoni1999/spotify-dl
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
      echo "Downloading $sourceKey ($source)"
      docker run -u 99:100 -v $spotifyPath:/download:rw --rm $dockerImage \
      --cf "/download/songs.txt" $arguments $source
    done

    chmod_unraid_file_permissions $spotifyPath
    
    echo "Finished Spotify Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Spotify Download!!" "Finished Spotify Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

