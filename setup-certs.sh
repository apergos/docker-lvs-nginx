#!/bin/bash

mkdir -p certs
cd certs

# all requests that come to nginx-redir should have the host header 'redirected' for server name
# requests might be on 80 or 443
echo 'redirected'
openssl genrsa -out redirected.key 2048
openssl req -new -key redirected.key -out redirected.csr -subj '/C=US/ST=Calfornia/L=San Francisco/O=Wikimedia Foundation/CN=redirected'
openssl x509 -req -days 365 -in redirected.csr -signkey redirected.key -out redirected.crt

# all requests that come to nginx-content via nginx-proxy should be on port 80
# and should have 'wronghostname' in the host header
# no cert needed in this case

# all requests that come to nginx-content directly should be on either port 80
# or port 443 and have 'contentserver' in the host header
echo 'contentserver'
openssl genrsa -out contentserver.key 2048
openssl req -new -key contentserver.key -out contentserver.csr -subj '/C=US/ST=Calfornia/L=San Francisco/O=Wikimedia Foundation/CN=contentserver'
openssl x509 -req -days 365 -in contentserver.csr -signkey contentserver.key -out contentserver.crt

# all requests that come to nginx-proxy should have 'wronghostname' in the host header
# requests might be on 80 or 443
echo 'wronghostname'
openssl genrsa -out wronghostname.key 2048
openssl req -new -key wronghostname.key -out wronghostname.csr -subj '/C=US/ST=Calfornia/L=San Francisco/O=Wikimedia Foundation/CN=wronghostname'
openssl x509 -req -days 365 -in wronghostname.csr -signkey wronghostname.key -out wronghostname.crt




