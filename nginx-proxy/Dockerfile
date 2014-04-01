FROM ariel/dev:base

ENV DEBIAN_FRONTEND noninteractive

# packages
RUN apt-get install -y nginx-full

# FIXME add the nginx config file stuff we want here
# FIXME add the cert and key too...


# setup for turning off arp for the service ip on the loopback interface
RUN echo "net.ipv4.conf.all.arp_ignore = 1" > /root/sysctl.conf
RUN echo "net.ipv4.conf.all.arp_announce = 2" >> /root/sysctl.conf

EXPOSE 80 443 22

CMD /usr/sbin/nginx -c /etc/nginx/nginx.conf && /usr/sbin/sshd -D

