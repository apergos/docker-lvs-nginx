#!/bin/bash

do_copy() {
    if [ -z "$1" ]; then
        echo "do_copy requires the container name as arg 1"
        exit 1
    fi
    if [ -z "$2" ]; then
        echo "do_copy requires the cert/key name as arg 2"
        exit 1
    fi

    addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$1"`
    if [ -z "$addr" ]; then
        echo "failed to find ip address of $1 container"
        exit 1
    fi
    sshpass -p testing scp -o StrictHostKeyChecking=no certs/${2}.key root@${addr}:/etc/ssl/private
    sshpass -p testing scp -o StrictHostKeyChecking=no certs/${2}.crt root@${addr}:/etc/ssl/certs/
}

do_copy "nginx-redir" "redirected"
do_copy "nginx-content" "contentserver"
do_copy "nginx-proxy" "wronghostname"
