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
    docker pull mikenye/youtube-dl
    for sourceKey in "${!sources[@]}";
    do
        source=${sources[$sourceKey]}
        format="bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio"
        outputFormat="${sourceKey}/%(upload_date)s.%(title)s.%(ext)s"
        
        echo "Downloading ${sourceKey}"
        docker run --rm -u $(id -u):$(id -g) -v ${youtubePath}:/workdir:rw mikenye/youtube-dl \
        -f "$format" --download-archive "${sourceKey}.txt" --write-thumbnail --add-metadata --ignore-errors \
        --write-auto-sub --cookies=cookies.txt --write-info-json --convert-subs=srt --sub-lang "en" \
        --merge-output-format mp4 -o "$outputFormat" "$source"
        
        folderPath="${youtubePath}/${sourceKey}"
        
        if ls $folderPath/*.webp 1> /dev/null 2>&1; then
            echo "Converting images"
            docker run --rm -v "$folderPath":/src --user=$(id -u):$(id -g) \
            madhead/imagemagick magick mogrify -format jpg /src/*.webp
        fi
            
        echo "Deleting webps"
        rm -rf $folderPath/*.webp
        
        if ls $folderPath/*.mp4 1> /dev/null 2>&1; then
            echo "generating thumnails"
            thumbnail_generate "$folderPath"
        fi
        
    done
    
    echo "Finished Youtube Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Youtube Download!!" "Finished Youtube Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

