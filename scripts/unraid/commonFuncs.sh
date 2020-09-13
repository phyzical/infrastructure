#!/bin/bash

notify () {
    /usr/local/emhttp/webGui/scripts/notify -i $1 -s "$2" -e "$3" -d "$4"
}

failed_func () {
    rm -f $1
    notify alert "$2" "Cronjob" "$3"
    exit 0
}

elapsed_time_message () {
    echo "Elapsed: $(($1 / 3600))hrs $((($1 / 60) % 60))min $(($1 % 60))sec"
}
