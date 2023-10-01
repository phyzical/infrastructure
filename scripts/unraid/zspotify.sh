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
    dockerImage="phyzical/zspotify"
    # dockerImage="cooper7692/zspotify-docker"
    docker pull $dockerImage

    docker run --rm -u 99:100 -v "$spotifyPath/zspotify/zs_config.json:/zs_config.json" \
      -v "$spotifyPath/music:/ZSpotify Music" -v "$spotifyPath/zspotify:/app" -v "$spotifyPath/music:/ZSpotify Podcasts" \
      $dockerImage --download="/app/uris.txt"
    
    # dockerImage="jsavargas/zspotify"
    # docker run --rm  -v "$spotifyPath/.zspotify:/root/.zspotify" -v "$spotifyPath/music:/root/Music" -it $dockerImage \
    #   --audio-format mp3 --music-dir /root/Music --antiban-time 20 \
    #   --episodes-dir /root/Music \
    #   --force-premium --skip-downloaded --bulk-download /root/.zspotify/uris.txt --config-dir /root/.zspotify/
    chmod_unraid_file_permissions $spotifyPath
    
    echo "Finished Spotify Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Spotify Download!!" "Finished Spotify Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi
