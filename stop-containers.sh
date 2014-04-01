#!/bin/bash

# stop and kill the three nginx containers if not already stopped
# removing all ip and container name info we may have added

python setup-etc-hosts.py --ids 'lvs-dr,nginx-backend,nginx-proxy,nginx-redirtarget' --clean

for container in lvs-dr nginx-content nginx-proxy nginx-redir; do
    docker stop "${container}"
    docker kill "${container}"
done
