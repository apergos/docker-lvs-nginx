#!/bin/bash

# stop, kill and delete the three nginx containers if not already gone

check_existence() {
    docker inspect "$1" >/dev/null 2>&1
    return "$?"
}

kill_with_fire() {
    if [ -z "$1" ]; then
        echo "kill_with_fire requires container name"
        exit 1
    fi
    check_existence "$1"
    if [ "$?" == '0' ]; then
        docker stop "$1"
        docker kill "$1"
        docker rm "$1"
    fi
}

kill_with_fire lvs-dr
kill_with_fire nginx-proxy
kill_with_fire nginx-content
kill_with_fire nginx-redir

