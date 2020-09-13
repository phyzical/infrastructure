#!/bin/bash

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
    declare -A sources=(
        ["JCS-Criminal-Psychology"]="https://www.youtube.com/playlist?list=UUYwVxWpjeKFWwu8TML-Te9A"
        ["Geographics"]="https://www.youtube.com/playlist?list=UUHKRfxkMTqiiv4pF99qGKIw"
        ["Biographics"]="https://www.youtube.com/playlist?list=UUlnDI2sdehVm1zm_LmUHsjQ"
        ["Megaprojects"]="https://www.youtube.com/playlist?list=UU0woBco6Dgcxt0h8SwyyOmw"
        ["ColdFusion"]="https://www.youtube.com/playlist?list=UU4QZ_LsYcvcq7qOsOhpAX4A"
        ["Infographics"]="https://www.youtube.com/playlist?list=UUfdNM3NAhaBOXCafH7krzrA"
        ["Adam-Savages-One-Day-Builds"]="https://www.youtube.com/playlist?list=PLJtitKU0CAej22ZWBqrimPkn0Bbo6ci-r"
        ["That-Chapter"]="https://www.youtube.com/playlist?list=UUL44k-cLrlsdr7PYuMU4yIw"
        ["I-Did-A-Thing"]="https://www.youtube.com/playlist?list=UUJLZe_NoiG0hT7QCX_9vmqw"
        ["VinWiki"]="https://www.youtube.com/playlist?list=UUefl-5pmhZmljwZTE2KrcdA"
        ["Today-I-Found-Out"]="https://www.youtube.com/playlist?list=UU64UiPJwM_e9AqAd7RiD7JA"
        ["Micheal-Reeves"]="https://www.youtube.com/playlist?list=UUtHaxi4GTYDpJgMSGy7AeSw"
        ["The-Royal-Institution"]="https://www.youtube.com/playlist?list=UUYeF244yNGuFefuFKqxIAXw"
    )
    for sourceKey in "${!sources[@]}";
    do
        source=${sources[$sourceKey]}
        format="bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio"
        outputFormat="${sourceKey}/%(upload_date)s.%(title)s.%(ext)s"
        
        echo "Downloading ${sourceKey}"
        docker run --rm -u $(id -u):$(id -g) -v ${youtubePath}:/workdir:rw mikenye/youtube-dl \
        -f "$format" --download-archive "${sourceKey}.txt" --write-thumbnail --add-metadata --ignore-errors \
        --write-auto-sub --cookies=cookies.txt --write-description --write-info-json --sub-format "srv1" --sub-lang "en" \
        --merge-output-format mp4 -o "$outputFormat" "$source"
        
        folderPath="${youtubePath}/${sourceKey}"
        echo "screenshots"
        for f in $folderPath/*.mp4;
        do
            echo "$f"
            docker run --rm -u $(id -u):$(id -g) -v "$folderPath":"$folderPath" -w "$folderPath" \
            jrottenberg/ffmpeg -loglevel 0 -n -ss 00:02:00 -i "$f" -vframes 1 "${f%.mp4}-thumb".jpg
        done
        
        echo "Converting images"
        docker run --rm -v "$folderPath":/src --user=$(id -u):$(id -g) madhead/imagemagick magick mogrify -resize 640x360 \
        -format jpg "/src/*-thumb.jpg"
        
        docker run --rm -v "$folderPath":/src --user=$(id -u):$(id -g) \
        madhead/imagemagick magick mogrify -resize 640x360 -format jpg /src/*.webp
        
        rm -rf $folderPath/*.webp
    done
    echo "Renaming subtitles"
    find ${youtubePath} -name "*.srv1" -exec rename .srv1 .srv {} \;
    
    echo "Finished Youtube Download!!"
    rm -f $LOCKFILE
    notify normal "Finished Youtube Download!!" "Finished Youtube Download, it took $(elapsed_time_message $SECONDS)" ""
    exit 0
fi

