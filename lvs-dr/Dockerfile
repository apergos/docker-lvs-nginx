FROM ariel/dev:base

ENV DEBIAN_FRONTEND noninteractive

# packages
RUN apt-get install -y ipvsadm

RUN echo '#!/bin/bash \n\
/sbin/ipvsadm -A -t ${1}:http -s wrr \n\
/sbin/ipvsadm -a -t ${1}:http -r ${2}:http -g -w 11 \n\
 \n\
/sbin/ipvsadm -A -t ${1}:https -s sh \n\
/sbin/ipvsadm -a -t ${1}:https -r ${2}:https -g -w 11 \n\
' > /root/setup_ipvs.sh

EXPOSE 80 443 22

CMD /usr/sbin/sshd -D



