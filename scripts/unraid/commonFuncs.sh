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
    docker pull jrottenberg/ffmpeg
    for f in "$folder"/*.mp4;
    do
        echo "$f"
        docker run --rm -u $(id -u):$(id -g) -v "$folder":"$folder" \
        -w "$folder" jrottenberg/ffmpeg -loglevel 0 -y -ss 00:02:00 -i "$f" \
        -vframes 1 "${f%.mp4}-screen".jpg
    done
    echo "Converting Thumbs for $folder"
    docker pull madhead/imagemagick
    docker run --rm -v "$folder":/src --user=$(id -u):$(id -g) \
    madhead/imagemagick magick mogrify -resize 640x360 -format jpg "/src/*.jpg"
}

add_timestamp() {
    while IFS= read -r line; do
        printf '%s %s\n' "$(date)" "$line";
    done
}

chmod_unraid_file_permissions(){
  echo "fixing file (666) and folder (766) permissions for $1"
  find $1 -type d -exec chmod 766 {} \;
  find $1 -type f -exec chmod 666 {} \;
}

move_episodes_to_season_folders () {
  years=($(seq 2000 1 $(date "+%Y")))
  sourcePath=$1
  destinationPath=$2
  nonSeasonFolders=$3
  for year in ${years[@]};
  do
    if find $sourcePath/$year*;
    then
      if [[ " ${nonSeasonFolders[*]} " =~ " ${sourcePath} " ]]; then
        echo "moving '$sourcePath/$year*' to '$destinationPath/Season 1/'"
        mkdir -p $destinationPath/Season\ 1 && mv $sourcePath/$year* $destinationPath/Season\ 1/
      else
        echo "moving '$sourcePath/$year*' to '$destinationPath/Season $year/'"
        mkdir -p $destinationPath/Season\ $year && mv $sourcePath/$year* $destinationPath/Season\ $year/
      fi
    fi
  done
}
