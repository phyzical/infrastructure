#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

LOCKFILE="/tmp/youtubeInProgress.lock"

trap 'failed_func $LOCKFILE "Youtube Failed!!" "Youtube Failed!! on line $LINENO"' ERR SIGTERM

if [ -e $LOCKFILE ]
then
    echo "Youtube running already."
    exit 1
else
    touch $LOCKFILE
    message="Youtube Started"
    notify normal $message "Youtube" $message
    youtubePath="/mnt/user/Downloads/youtube"
    dockerImage="phyzical/yt-dlp"
    docker pull $dockerImage
    for channelName in "${!urls[@]}";
    do
        url=${urls[$channelName]}
        format="bv*[ext=mp4]+ba[ext=m4a]"
        outputFormat="$channelName/processing/%(upload_date)s.%(title)s.%(ext)s"
        oneMonthAgo="$(date -d "-1 months" '+%Y%m%d')"
        showPath="$youtubePath/$channelName"
        processingPath="$showPath/processing"

        echo "Downloading $channelName"
        docker run --rm -u $(id -u):$(id -g) -v $youtubePath:/workdir:rw $dockerImage \
        -f "$format" --download-archive "$channelName.txt" --write-thumbnail --add-metadata \
        --no-write-playlist-metafiles --compat-options no-youtube-unavailable-videos --sponsorblock \
        --write-auto-sub --cookies=cookies.txt --write-info-json --convert-subs=srt --sub-lang "en" \
        --datebefore $oneMonthAgo --merge-output-format mp4 -o "$outputFormat" "$url"
        
        if ls $processingPath/*.webp 1> /dev/null 2>&1;
        then
            docker run --rm -v "$processingPath":/src --user=$(id -u):$(id -g) \
            madhead/imagemagick magick mogrify -format jpg /src/*.webp
        fi
            
        rm -rf $processingPath/*.webp
        
        if ls $processingPath/*.mp4 1> /dev/null 2>&1;
        then
            thumbnail_generate "$processingPath"
        fi

        for text in ${textRemovals[@]}; do
            rename "$text" "" $processingPath/*
        done

        if [[ " ${manualShows[@]} " =~ " $channelName " ]];
        then
            mv "$processingPath/*" "$showPath/"
        else
            #move to season folders
            years=($(seq 2000 1 $(date "+%Y")))
            for year in ${years[@]};
            do
                mv "$processingPath/$year*" "$showPath/Season $year/"
            done
        fi
    done
    
    echo "Finished Youtube Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Youtube Download!!" "Finished Youtube Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

