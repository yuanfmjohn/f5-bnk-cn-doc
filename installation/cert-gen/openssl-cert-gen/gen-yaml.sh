#!/bin/bash

BASE_DIR=$PWD
ROOT_CERT_PEM=rootCA.crt
SERVER_CERT_PEM=rabbit-server.crt
SERVER_KEY_PEM=rabbit-server.key
CLIENT_CERT_PEM=rabbit-client.crt
CLIENT_KEY_PEM=rabbit-client.key

create_rabbitmq_server_secrets_yaml() {
    SERVER_SECRETS_YAML="rabbitmq-server-certs.yaml"
    echo Generating ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " name: server-certs" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-cert.pem: `cat $SERVER_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-key.pem: `cat $SERVER_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
}

create_rabbitmq_client_secrets_yaml() {
    CLIENT_SECRETS_YAML="rabbitmq-client-certs.yaml"
    echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " name: client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-cert.pem: `cat $CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-key.pem: `cat $CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
}

create_rabbitmq_server_secrets_yaml
create_rabbitmq_client_secrets_yaml
