#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

LOCKFILE="/tmp/spotifyInProgress.lock"
trap 'failed_func $LOCKFILE "Spotify Failed!!" "Spotify Failed!! on line $LINENO"' ERR SIGTERM
# declare -A sources=(
#   ["artist"]="https://open.spotify.com/artist/0DGqabk3gsZWS8zEdgt1m5?si=ECdth_rMSnafUkGLskc08g"
#   ["album"]="https://open.spotify.com/album/3XtEGVx9uh7J46nBzEc1VS?si=hUiwIxK0SZeCtWlEMUbmPA"
#   ["playlist"]="https://open.spotify.com/playlist/46HnjD7FcxjwcTnbtoDVxI?si=je1jJpTvRCOl9jvo_tB8TA"
#   ["song"]="https://open.spotify.com/track/2wBjgUXl43nSK7k3jVrSac?si=O6GOeMIkRyy9q-bBBYGZJQ"
# )
if [ -e $LOCKFILE ]
then
    echo "Spotify running already."
    exit 1
else
    touch $LOCKFILE
    message="Spotify Started"
    notify normal $message "Spotify" $message
    spotifyPath="/mnt/user/Downloads/spotify"
    spotifyPath="$PWD/testfolder"
    for sourceKey in "${!sources[@]}";
    do
        source=${sources[$sourceKey]}
        echo "Downloading ${source}"
        docker run -u $(id -u):$(id -g) -v ${spotifyPath}:/download:rw --rm phyzical/spotify-dl "$source"
    done
    
    echo "Finished Spotify Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Spotify Download!!" "Finished Spotify Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

