#! /bin/bash

# Geerate rootCA key and cert
openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -subj "/CN=demo.f5net.com/C=US/L=Seattle" -keyout rootCA.key -out rootCA.crt

# Create a server key
openssl genrsa -out rabbit-server.key 2048

# Create a csr.conf and  raise a csr request
openssl req -new -key rabbit-server.key -out rabbit-server.csr -config csr.conf

# Create a server-cert.conf and generate rabbit-server.crt for rabbit-server.key
openssl x509 -req -in rabbit-server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out rabbit-server.crt -days 365 -sha256 -extfile server-cert.conf

# Create a client key
openssl genrsa -out rabbit-client.key 2048

# Create a csr.conf and  raise a csr request
openssl req -new -key rabbit-client.key -out rabbit-client.csr -config client-csr.conf

# Create a client-cert.conf and generate rabbit-client.crt for rabbit-client.key
openssl x509 -req -in rabbit-client.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out rabbit-client.crt -days 365 -sha256 -extfile client-cert.conf

