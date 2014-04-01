#!/bin/bash

in_array() {
    local elt
    for elt in "${@:2}"; do
        [[ "$elt" == "$1" ]] && return 0
    done
    return 1
}

# see if we already have lvs-dr and nginx-proxy set up with
# extra ip address; if so exit

# FIXME do that

# collect all container ip addresses in use
addresses_used=()
containers=`docker ps | tail -n +2 | cut -s -f 1 -d ' '`
for c in $containers; do
   container_addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "$c"`
   addresses_used+=($container_addr)
done

# get the first two octets of the ip address of the nginx proxy, we
# need to reuse those (this will not have the trailing dot)
prefix=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "nginx-proxy" | cut -f 1,2 -d '.'`
if [ -z "$prefix" ]; then
    echo "failed to find the nginx proxy container, trying first two octets of docker0"
    prefix=`ip addr list docker0 | grep 'inet ' | awk '{ print $2 }' | sed -e 's|/.*$||g;' | cut -f 1,2 -d '.'`
    if [ -z "$prefix" ]; then
        echo "failed to find ip addr for docker0 device, giving up"
        exit 1
    fi
fi

echo "using prefix $prefix"

# collect the last two octets of every address in use by docker in this subnet
suffixes_used=()
for a in ${addresses_used[@]}; do
    prefix_a=`echo $a | cut -f 1,2 -d '.'`
    if [ "${prefix_a}" == "$prefix" ]; then
         suffix_a=`echo $a | cut -f 3,4 -d '.'`
         suffixes_used+=($suffix_a)
    fi
done

good_suffix=""
# find an address not in use on that subnet
for i in `seq 2 1 253`; do
    for j in `seq 2 1 253`; do
        in_array "$i.$j" ${suffixes_used[@]}
        if [ "$?" != '0' ]; then
            good_suffix="$i.$j"
            break
        fi
    done
    if [ -n "${good_suffix}" ]; then
        break
    fi
done

if [ -z "$good_suffix" ]; then
    echo "failed to find a good addr, you must have a lot of containers going."
    echo "consider shutting down a few to free up an address on the $prefix subnet."
    exit 1
fi

good_address="${prefix}.${good_suffix}"
echo "using adress ${good_address} for lvs"

proxy_addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "nginx-proxy"`
contentserver_addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "nginx-content"`
redirserver_addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "nginx-redir"`
lvs_addr=`docker inspect "--format={{.NetworkSettings.IPAddress}}" "lvs-dr"`

if [ -z "$proxy_addr}" ]; then
    echo "couldn't find address of nginx proxy, can't proceed"
    exit 1
fi
if [ -z "$contentserver_addr}" ]; then
    echo "couldn't find address of nginx content server, can't proceed"
    exit 1
fi
if [ -z "$redirserver_addr}" ]; then
    echo "couldn't find address of nginx redir server, can't proceed"
    exit 1
fi
if [ -z "$lvs_addr}" ]; then
    echo "couldn't find address of lvs dr server, can't proceed"
    exit 1
fi

# make sure kernel is set up for lvs in containers
modprobe ip_vs
if [ "$?" != '0' ]; then
    echo "setup of kernel for ipvs failed, giving up"
    exit 1
fi

# turn off arp for the extra address on the target server
sshpass -p testing ssh -o StrictHostKeyChecking=no   -t -t -l root ${proxy_addr} /sbin/sysctl -p /root/sysctl.conf
# add the ip addr used for lvs dr to target server
sshpass -p testing ssh -o StrictHostKeyChecking=no   -t -t -l root ${proxy_addr} ip addr add ${good_address}/32 label "lo:LVS" dev lo

# add the ip addr used for lvs dr to lvs server
sshpass -p testing ssh -o StrictHostKeyChecking=no   -t -t -l root ${lvs_addr} ip addr add ${good_address}/32 label "eth0:0" dev eth0
# set up lvs
sshpass -p testing ssh -o StrictHostKeyChecking=no  -t -t -l root ${lvs_addr} bash /root/setup_ipvs.sh ${good_address} ${proxy_addr}

# what we expect to have happen for a request:

# we send request for "contentserver" either http or https
# this goes directly to nginx-content (so contentserver has same ip)
# nginx-content server checks url:
# if url contains some certain stuff it sends back a redirect
# to another server nginx-redir
# we go there and fetch our content

# now if we have a hostname that is a cname for "contentserver"
# and we really want the client to use the contentserver name in requests.
# and not this other name... let's call that other hostname "wronghostname"

# we send request for 'wronghostname" either http or https
# ip for this hostname is extra ip addr on lvs eth0
# lvs server sees it, uses dr to send packets to nginx proxy
# nginx proxy sees "wronghostname" as host name in Host: Header
# it proxypasses to nginx-content server on port 80 for that hostname
# nginx-content server checks hostname:
# oh this is wrong-hostname. so send a redirect back to the client
# to 'contentserver'
# nginx-proxy sees this answer and sends it back to us
# our next request will be for 'contentserver'
# this will go directly to nginx-content and cut out lvs, as it should.
#
# so this means we want
#
# contentserver has ip addr of nginx-content container
# wronghostname has ip addr of nginx-proxy addr on lo, = ip addr ov lvs-dr on eth0:0
# nginx-proxy knows to forward requests to nginx-content for wronghostname
#    but no othe requests
# nginx-content knows to redir certain urls to "redirected" (nginx-redir)
# nginx-content knows to redir wronghostname requests to contentserver requests

# we know ip addresses on docker server for contentserver, wronghostname, nginx-redir
# lvs-dr knows ip addresses for ... nothing, it jut does lvs dr via the table
# nginx-proxy knows ip addresses for nginx-content... actually it just needs the
# ip address and not the name, and proxy_pass to there and then proxy_set_header Host $host;
# to pass along the host header it was given.
# nginx-content knows ip addresses for ... nothing, it just responds directly to requests

echo "add to your /etc/hosts:"
echo "${contentserver_addr} contentserver"
#echo "${proxy_addr} wronghostname"
echo "${redirserver_addr} redirected"
echo "${good_address} wronghostname"
