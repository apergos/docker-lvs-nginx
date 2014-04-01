#!/bin/bash

do_config_copy() {
    if [ -z "$1" ]; then
        echo "do_config_copy requires the container name as arg 1"
        exit 1
    fi

    addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$1"`
    if [ -z "$addr" ]; then
        echo "failed to find ip address of $1 container"
        exit 1
    fi
    sshpass -p testing scp -o StrictHostKeyChecking=no "${1}/conf/nginx.conf" root@${addr}:/etc/nginx/
    sitesavail=`ls ${1}/conf/ | grep -v nginx.conf | grep -v '~'`
    sshpass -p testing scp -o StrictHostKeyChecking=no "${1}/conf/${sitesavail}" root@${addr}:/etc/nginx/sites-available/
    sshpass -p testing ssh -o StrictHostKeyChecking=no -t -t -l root ${addr} rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
    sshpass -p testing ssh -o StrictHostKeyChecking=no -t -t -l root ${addr} '(cd /etc/nginx/sites-enabled; ln -s ../sites-available/* .)'

}

do_html_copy() {
    if [ -z "$1" ]; then
        echo "do_html_copy requires the container name as arg 1"
        exit 1
    fi

    htmldir="/usr/share/nginx/www/"
    if [ -n "$2" ]; then
        htmldir="${htmldir}${2}/"
    fi

    addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$1"`
    if [ -z "$addr" ]; then
        echo "failed to find ip address of $1 container"
        exit 1
    fi
#/usr/share/nginx/www/redirtesting/index.html

    sshpass -p testing ssh -o StrictHostKeyChecking=no -t -t -l root "${addr}" mkdir -p "${htmldir}"
    sshpass -p testing scp -o StrictHostKeyChecking=no "${1}/html/index.html" "root@${addr}:${htmldir}"

}

do_nginx_restart() {
    if [ -z "$1" ]; then
        echo "restart_nginx requires the container name as arg 1"
        exit 1
    fi

    addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$1"`
    if [ -z "$addr" ]; then
        echo "failed to find ip address of $1 container"
        exit 1
    fi

    sshpass -p testing ssh -o StrictHostKeyChecking=no -t -t -l root "${addr}" /etc/init.d/nginx restart
}

do_config_copy "nginx-redir" "redirected"
do_config_copy "nginx-content" "contentserver"
do_config_copy "nginx-proxy" "wronghostname"

# now deal with the html
do_html_copy "nginx-redir" "redirtesting"
do_html_copy "nginx-content"
do_html_copy "nginx-proxy"

do_nginx_restart "nginx-redir"
do_nginx_restart "nginx-content"
do_nginx_restart "nginx-proxy"
