#!/bin/bash

folder="$1"
for f in $folder/*.mp4;
do
  docker run --rm -u $(id -u):$(id -g) -v "$folder":"$folder" \
  -w "$folder" jrottenberg/ffmpeg -loglevel 0 -y -ss 00:02:00 -i "$f" \
  -vframes 1 "${f%.mp4}-thumb".jpg
fi
echo "Converting Thumbs"
docker run --rm -v "$folder":/src --user=$(id -u):$(id -g) \
madhead/imagemagick magick mogrify -resize 640x360 -format jpg "/src/*-thumb.jpg"
