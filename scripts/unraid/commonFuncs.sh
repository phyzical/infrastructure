#!/bin/bash

notify () {
    /usr/local/emhttp/webGui/scripts/notify -i $1 -s "$2" -e "$3" -d "$4" || echo "/usr/local/emhttp/webGui/scripts/notify is missing"
}

failed_func () {
    rm -f $1
    notify alert "$2" "Cronjob" "$3"
    exit 0
}

elapsed_time_message () {
    echo "Elapsed: $(($1 / 3600))hrs $((($1 / 60) % 60))min $(($1 % 60))sec"
}

thumbnail_generate() {
    folder="$1"
    for f in "$folder"/*.mp4;
    do
        echo "$f"
        docker run --rm -u $(id -u):$(id -g) -v "$folder":"$folder" \
        -w "$folder" jrottenberg/ffmpeg -loglevel 0 -y -ss 00:02:00 -i "$f" \
        -vframes 1 "${f%.mp4}-screen".jpg
    done
    echo "Converting Thumbs"
    docker run --rm -v "$folder":/src --user=$(id -u):$(id -g) \
    madhead/imagemagick magick mogrify -resize 640x360 -format jpg "/src/*.jpg"
}
