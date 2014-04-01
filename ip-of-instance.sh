#!/bin/bash

if [ -n "$1" ]; then
    host="$1"
else
    echo "Usage: $0 container-name"
    exit 1
fi

IPADDR=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$host"`

if [ -z "$IPADDR" ]; then
    echo "Failed to find IP address for $host"
    exit 1
else
    echo "$IPADDR"
fi
