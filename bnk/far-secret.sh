#!/bin/bash

# Service Account JSON key (원본 JSON 그대로)
SERVICE_ACCOUNT_KEY=$(cat cne_pull_64.json)

# _json_key_base64:<base64(json)>
SERVICE_ACCOUNT_K8S_SECRET=$(echo -n "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

# dockerconfigjson 전체 구조를 다시 base64 인코딩
DOCKERCONFIGJSON=$(echo -n "{\"auths\":{\"repo.f5.com\":{\"auth\":\"${SERVICE_ACCOUNT_K8S_SECRET}\"}}}" | base64 -w 0)

cat << EOF > far-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: far-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${DOCKERCONFIGJSON}
EOF
