#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

source $DIR/commonFuncs.sh

LOCKFILE="/tmp/youtubeInProgress.lock"

trap 'failed_func $LOCKFILE "Youtube Failed!! with code ($?)" "Youtube Failed!! on line $LINENO"' ERR SIGTERM

textRemovalRegex=$1

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
        --no-write-playlist-metafiles --compat-options no-youtube-unavailable-videos --sponsorblock-remove "default" \
        --write-auto-sub --cookies cookies.txt --write-info-json --convert-subs=srt --sub-lang "en" --ignore-no-formats-error \
        --match-filter "!is_live & !was_live" \
        --datebefore $oneMonthAgo --merge-output-format mp4 -o "$outputFormat" "$url"

        if [ -d "$processingPath" ]; 
        then
            if ls $processingPath/*.webp 1> /dev/null 2>&1;
            then
                echo "Converting images matching ($processingPath/*.webp)"
                docker run --rm -v "$processingPath":/src --user=$(id -u):$(id -g) \
                madhead/imagemagick magick mogrify -format jpg /src/*.webp
            fi
                
            echo "Deleting webps matching ($processingPath/*.webp)"
            rm -rf $processingPath/*.webp
            
            if ls $processingPath/*.mp4 1> /dev/null 2>&1;
            then
                echo "generating thumnails for ($processingPath/*.mp4)"
                thumbnail_generate "$processingPath"
            fi

            echo "Replacing text in filename"
            filesToRename=$(find "$processingPath" -type f | sed -e 's/ /\~_-/g')
            for old in $filesToRename; do
              old=$(echo "$old" | sed -e 's/\~_-/ /g')
              new=$(echo "$old" | sed -e "s/$textRemovalRegex//g")
              if [ "$old" != "$new" ]; then  
                mv -v "$old" "$new"
              fi
            done

            if [[ " ${manualShows[@]} " =~ " $channelName " ]];
            then
                echo "moving '$processingPath/*' to '$showPath/'"
                mv $processingPath/* $showPath/ || echo "$processingPath/ must be empty"
            else
                move_episodes_to_season_folders "$processingPath" "$showPath"
            fi
        fi
    done

    remove_empty_folders "/mnt/user/Downloads/youtube/"

    echo "Finished Youtube Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Youtube Download!!" "Finished Youtube Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

