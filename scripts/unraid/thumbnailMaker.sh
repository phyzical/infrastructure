#!/bin/bash

folder="$1"
docker run --rm -u $(id -u):$(id -g) -v "$folder":"$folder" \
-w "$folder" jrottenberg/ffmpeg -loglevel 0 -y -ss 00:02:00 -i "$f" \
-vframes 1 "${f%.mp4}-thumb".jpg