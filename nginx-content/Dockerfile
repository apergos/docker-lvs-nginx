FROM ariel/dev:base

ENV DEBIAN_FRONTEND noninteractive

# packages
RUN apt-get install -y nginx-full

# FIXME add the web server content we want here
# FIXME add the nginx conf file stuff we want here

EXPOSE 80 443 22

CMD /usr/sbin/nginx -c /etc/nginx/nginx.conf && /usr/sbin/sshd -D

