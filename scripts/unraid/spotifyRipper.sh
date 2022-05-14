#!/bin/bash
## This uses the following repository https://github.com/putty182/spotify-ripper
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
    dockerImage="putty182/spotify-ripper"
    docker pull $dockerImage

    docker run -i -v "$spotifyPath/config:/config" -v "$spotifyPath/songs:/music" putty182/spotify-ripper

    chmod_unraid_file_permissions $spotifyPath
    
    echo "Finished Spotify Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Spotify Download!!" "Finished Spotify Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

