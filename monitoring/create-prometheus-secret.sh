# prometheus-secret 생성 (SSL 인증서용)
# 자체 서명 인증서 생성
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/prometheus.key \
  -out /tmp/prometheus.crt \
  -subj "/CN=prometheus/O=monitoring"

# Secret 생성
kubectl create secret generic prometheus-secret \
  -n f5-bnk \
  --from-file=tls.crt=/tmp/prometheus.key \
  --from-file=tls.key=/tmp/prometheus.crt

# 또는 빈 Secret 생성 (SSL이 필요 없는 경우)
kubectl create secret generic prometheus-secret \
  -n f5-bnk \
  --from-literal=dummy=dummy