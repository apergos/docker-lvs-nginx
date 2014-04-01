#!/bin/bash

# create lvs base image if needed,
# create lvs container if needed,
# start lvs container if needed

# create nginx base images if needed,
# create the three nginx containers if needed,
# start the containers if needed,
# add ips and container names to /etc/hosts on all containers if not already present

check_existence() {
    docker inspect "$1" >/dev/null 2>&1
    return "$?"
}

check_running() {
    is_running=`docker inspect "$1" State.Running`
    if [ "$is_running" == "true" ]; then
        return 1
    else
        return 0
    fi
}

do_image_and_container() {

    #check for image, build if needed
    result=`check_existence "ariel/${1}:${2}"`
    if [ "$?" != '0' ]; then
        echo "building image ${1}:${2}"
        ( cd "${1}-${2}"; docker build --rm -t "ariel/${1}:${2}" . )
        if [ "$?" != "0" ]; then
           echo "failed to build image ariel/${1}:${2}"
	   errors=1
	   return
        fi
    fi

    # check for container, create if needed
    check_existence "${1}-${2}"
    if [ "$?" != '0' ]; then
        echo "creating container ${1}-${2}"
        docker run  -t  -d --privileged --name "${1}-${2}" -v /sys/fs/selinux:/selinux:ro "ariel/${1}:${2}"
        if [ "$?" != "0" ]; then
           echo "failed to create container ${1}-${2}"
	   errors=1
           return
        fi   
    else
        check_running "${1}-${2}"
        if [ "$?" == '0' ]; then
            echo "starting container ${1}-${2}"
            docker start "${1}-content"
            if [ "$?" != "0" ]; then
               echo "failed to start container ${1}-${2}"
               errors=1
	       return
            fi   
        else
            echo "container ${1}-${2} already exists and running"
        fi
    fi
}

errors=0

do_image_and_container "lvs" "dr"

for nginxtype in proxy content redir; do
    do_image_and_container "nginx" "${nginxtype}"
done

if [ "$errors" != "0" ]; then
    echo "errors encountered during setup, not adding ip entries to /etc/hosts"
    exit 1
fi


echo "cleaning up host/ip entries"
python setup-etc-hosts.py --ids 'lvs-dr,nginx-content,nginx-proxy,nginx-redir' --clean
echo "setting up host/ip entries"
python setup-etc-hosts.py --ids 'lvs-dr,nginx-content,nginx-proxy,nginx-redir'



