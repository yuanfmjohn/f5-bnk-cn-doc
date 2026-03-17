#!/bin/bash

BASE_DIR=${PWD}
WORKING_DIR=""
CAN=""
SAN=""
N_CERTS=""
TLS_DIR=""

ROOT_CERTS_DIR=""
ROOT_SECRETS_DIR=""
SERVER_CERTS_DIR=""
SERVER_SECRETS_DIR=""
CLIENT_CERTS_DIR=""
CLIENT_SECRETS_DIR=""

ROOT_CERT_PEM=ca_certificate.pem
ROOT_KEY_PEM=ca_key.pem
SERVER_CERT_PEM=server_certificate.pem
SERVER_KEY_PEM=server_key.pem
CLIENT_CERT_PEM=""
CLIENT_KEY_PEM=""

SERVER_SECRETS_YAML=""
CLIENT_SECRETS_YAML=""

API_SERVER_SECRETS="API_SERVER_SECRETS=cwc-license-certs.yaml"
RABBIT_SERVER_SECRETS=""
RABBIT_CLIENT_SECRETS=""

init() {
    if [ "${SERVICE}" = "rabbit" ]; then
        WORKING_DIR=$BASE_DIR/rabbit-secrets
        CAN="f5net"
    elif [ "$SERVICE" = "api-server" ]; then
        WORKING_DIR=$BASE_DIR/api-server-secrets
        CAN="client"
    elif [ "$SERVICE" = "qkview" ]; then
        WORKING_DIR=$BASE_DIR/qkview-secrets
        CAN="f5net"
    elif [ "$SERVICE" = "qkview-orchestrator" ]; then
        WORKING_DIR=$BASE_DIR/qkview-orchestrator-secrets
        CAN="f5net"
    elif [ "$SERVICE" = "cnf" ]; then
        WORKING_DIR=$BASE_DIR/cnf-secrets
    fi
    echo "------------------------------------------------------------------"
    echo "Service                   = ${SERVICE}"
    echo "Subject Alternate Name    = ${SAN}"
    echo "Working directory         = ${WORKING_DIR}"
    echo "------------------------------------------------------------------"

    # remove working dir if already present
    rm -r ${WORKING_DIR}

    mkdir -p ${WORKING_DIR}/ssl/ca
    mkdir -p ${WORKING_DIR}/ssl/ca/secrets
    mkdir -p ${WORKING_DIR}/ssl/ca/certs
    mkdir -p ${WORKING_DIR}/ssl/server
    mkdir -p ${WORKING_DIR}/ssl/server/certs
    mkdir -p ${WORKING_DIR}/ssl/server/secrets
    mkdir -p ${WORKING_DIR}/ssl/client
    mkdir -p ${WORKING_DIR}/ssl/client/certs
    mkdir -p ${WORKING_DIR}/ssl/client/secrets

    ROOT_CERTS_DIR=${WORKING_DIR}/ssl/ca/certs/
    ROOT_SECRETS_DIR=${WORKING_DIR}/ssl/ca/secrets/
    SERVER_CERTS_DIR=${WORKING_DIR}/ssl/server/certs/
    SERVER_SECRETS_DIR=${WORKING_DIR}/ssl/server/secrets/
    CLIENT_CERTS_DIR=${WORKING_DIR}/ssl/client/certs/
    CLIENT_SECRETS_DIR=${WORKING_DIR}/ssl/client/secrets/
}
generate_secrets() {
    echo "Generating Secrets ..."
    CNF_WORKING_DIR=$WORKING_DIR
    WORKING_DIR=$BASE_DIR
    cd ${WORKING_DIR}/cert-gen/basic
    if [ "${SERVICE}" = "cnf" ]; then
        make -f grpc/grpc.mk SERVER_ALT_NAME=$SAN BASE_DIR=$BASE_DIR CNF_WORKING_DIR=${CNF_WORKING_DIR}
	make -f grpc/grpc.mk gen-secrets SERVER_ALT_NAME=$SAN BASE_DIR=$BASE_DIR CNF_WORKING_DIR=${CNF_WORKING_DIR}
        make -f grpc/grpc.mk create-secret-yamls SERVER_ALT_NAME=$SAN BASE_DIR=$BASE_DIR CNF_WORKING_DIR=${CNF_WORKING_DIR}
    else
        make CN=f5net CLIENT_ALT_NAME=${CAN} SERVER_ALT_NAME=${SAN} CLIENT_CERTS=${default}
    fi
}
copy_secrets() {
    echo "Copying secrets ..."
    TLS_DIR=${WORKING_DIR}/cert-gen/basic/result
    cp ${TLS_DIR}/${ROOT_CERT_PEM} ${ROOT_CERTS_DIR}
    cp ${TLS_DIR}/${ROOT_KEY_PEM} ${ROOT_SECRETS_DIR}
    cp ${TLS_DIR}/${SERVER_CERT_PEM} ${SERVER_CERTS_DIR}
    cp ${TLS_DIR}/${SERVER_KEY_PEM} ${SERVER_SECRETS_DIR}
    CLIENT_CERT_PEM=client_certificate.pem
    CLIENT_KEY_PEM=client_key.pem
    cp ${TLS_DIR}/${CLIENT_CERT_PEM} ${CLIENT_CERTS_DIR}
    cp ${TLS_DIR}/${CLIENT_KEY_PEM} ${CLIENT_SECRETS_DIR}
    for i in $(seq 1 $N_CERTS_NEW)
        do
        VAR1=client
        VAR2=_certificate.pem
        CLIENT_CERT_PEM=${VAR1}$i${VAR2}
        echo $CLIENT_CERT_PEM
        VAR3=client
        VAR4=_key.pem
        CLIENT_KEY_PEM="${VAR3}$i${VAR4}"
        echo $CLIENT_KEY_PEM
        cp ${TLS_DIR}/${CLIENT_CERT_PEM} ${CLIENT_CERTS_DIR}
        cp ${TLS_DIR}/${CLIENT_KEY_PEM} ${CLIENT_SECRETS_DIR}
        done 
}

## Delete the repository
remove_tls_dir() {
    rm -rf ${WORKING_DIR}/cert-gen
}

# Script execution starts here!
for i in "$@"; do
  case $i in
    -s=*|--service=*)
      SERVICE="${i#*=}"
      shift # past argument=value
      ;;
    -a=*|--alternatename=*)
      SAN="${i#*=}"
      shift # past argument=value
      ;;
    -n=*|--ncerts=*)
      N_CERTS="${i#*=}"
      shift # past argument=value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done
create_api_server_secrets_yaml() {
    SERVER_SECRETS_YAML="cwc-license-certs.yaml"
    echo Generating ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " name: cwc-license-certs" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " ca-root-cert: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-cert: `cat $SERVER_CERTS_DIR/$SERVER_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-key: `cat $SERVER_SECRETS_DIR/$SERVER_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
}
create_api_client_secrets_yaml() {
    CLIENT_SECRETS_YAML="cwc-license-client-certs.yaml"
    echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " name: cwc-license-client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " ca-root-cert: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-cert: `cat $CLIENT_CERTS_DIR/$CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-key: `cat $CLIENT_SECRETS_DIR/$CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
}
create_qkview_server_secrets_yaml() {
    SERVER_SECRETS_YAML="qkview-server-certs.yaml"
    echo Generating ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " name: qkview-server-certs" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-cert.pem: `cat $SERVER_CERTS_DIR/$SERVER_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-key.pem: `cat $SERVER_SECRETS_DIR/$SERVER_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
}
create_qkview_client_secrets_yaml() {
    CLIENT_SECRETS_YAML="qkview-client-certs.yaml"
    echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " name: qkview-client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-cert.pem: `cat $CLIENT_CERTS_DIR/$CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-key.pem: `cat $CLIENT_SECRETS_DIR/$CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
}
create_qkview_orchestrator_server_secrets_yaml() {
    SERVER_SECRETS_YAML="qkview-orchestrator-server-certs.yaml"
    echo Generating ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " name: qkview-orchestrator-server-certs" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-cert.pem: `cat $SERVER_CERTS_DIR/$SERVER_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-key.pem: `cat $SERVER_SECRETS_DIR/$SERVER_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
}
create_qkview_orchestrator_client_secrets_yaml() {
    CLIENT_SECRETS_YAML="qkview-orchestrator-client-certs.yaml"
    echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " name: qkview-orchestrator-client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-cert.pem: `cat $CLIENT_CERTS_DIR/$CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-key.pem: `cat $CLIENT_SECRETS_DIR/$CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
}
create_rabbitmq_server_secrets_yaml() {
    SERVER_SECRETS_YAML="rabbitmq-server-certs.yaml"
    echo Generating ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " name: server-certs" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-cert.pem: `cat $SERVER_CERTS_DIR/$SERVER_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$SERVER_SECRETS_YAML
    echo " server-key.pem: `cat $SERVER_SECRETS_DIR/$SERVER_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$SERVER_SECRETS_YAML
}
create_rabbitmq_client_secrets_yaml() {
    CLIENT_SECRETS_YAML="rabbitmq-client-certs.yaml"
    echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " name: client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-cert.pem: `cat $CLIENT_CERTS_DIR/$CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    echo " client-key.pem: `cat $CLIENT_SECRETS_DIR/$CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
    for i in $(seq 1 $N_CERTS_NEW)
        do
        CLIENT_SECRETS_YAML=rabbitmq-client-$i-certs.yaml
        VAR1=client
        VAR2=_certificate.pem
        CLIENT_CERT_PEM=${VAR1}$i${VAR2}
        echo $CLIENT_CERT_PEM
        VAR3=client
        VAR4=_key.pem
        CLIENT_KEY_PEM="${VAR3}$i${VAR4}"
        echo $CLIENT_KEY_PEM
        echo Generating ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo "kind: Secret" > ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo "apiVersion: v1" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo "metadata:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo " name: client-certs" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo "data:" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo " ca-root-cert.pem: `cat $ROOT_CERTS_DIR/$ROOT_CERT_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo " client-cert.pem: `cat $CLIENT_CERTS_DIR/$CLIENT_CERT_PEM | base64 -w 0`"  >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        echo " client-key.pem: `cat $CLIENT_SECRETS_DIR/$CLIENT_KEY_PEM | base64 -w 0`" >> ${BASE_DIR}/$CLIENT_SECRETS_YAML
        done 
}
init
a=1
default=${N_CERTS:-0}
N_CERTS_NEW=$(($N_CERTS - $a))
generate_secrets $default

if [ "${SERVICE}" != "cnf" ]; then
    copy_secrets $N_CERTS_NEW
fi    

if [ "${SERVICE}" = "rabbit" ]; then
    create_rabbitmq_server_secrets_yaml
    create_rabbitmq_client_secrets_yaml $N_CERTS_NEW
elif [ "$SERVICE" = "api-server" ]; then
    create_api_server_secrets_yaml
    create_api_client_secrets_yaml
elif [ "$SERVICE" = "qkview" ]; then
    create_qkview_server_secrets_yaml
    create_qkview_client_secrets_yaml
elif [ "$SERVICE" = "qkview-orchestrator" ]; then
    create_qkview_orchestrator_server_secrets_yaml
    create_qkview_orchestrator_client_secrets_yaml
fi
