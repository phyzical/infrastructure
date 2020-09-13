#!/bin/bash

folder=""
find "$folder" -name "*.mp4" -exec docker run --rm -u $(id -u):$(id -g) -v "$folder":"$folder" -w "$folder" jrottenberg/ffmpeg -ss 00:02:00 -i {} -vframes 1 {}-screen.jpg \;
docker run --rm -it -v "$folder":/src --user=$(id -u):$(id -g) madhead/imagemagick magick mogrify -resize 640x360 -format jpg "/src/*-screen.jpg"