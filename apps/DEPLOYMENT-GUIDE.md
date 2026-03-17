# Cafe 애플리케이션 배포 가이드 (HTTP/HTTPS)

이 가이드는 cafe 애플리케이션을 80(HTTP) 및 443(HTTPS) 포트로 서비스하는 방법을 설명합니다.

## 📋 사전 요구사항

1. **Kubernetes 클러스터** (v1.19 이상 권장)
2. **Ingress Controller 설치** (NGINX Ingress Controller 권장)
3. **kubectl** 명령줄 도구
4. **openssl** (TLS 인증서 생성용)

## 🔧 Ingress Controller 설치

### NGINX Ingress Controller 설치 (미설치 시)

```bash
# Helm 사용 시
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx

# 또는 kubectl 사용 시
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

설치 확인:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## 🔐 1단계: Self-signed TLS 인증서 생성

### 방법 1: 스크립트 사용 (권장)

```bash
# 실행 권한 부여
chmod +x create-tls-cert.sh

# 기본 도메인(cafe.example.com)으로 실행
./create-tls-cert.sh

# 또는 사용자 지정 도메인으로 실행
./create-tls-cert.sh mycafe.local
```

### 방법 2: 수동 생성

```bash
# 1. 개인키 생성
openssl genrsa -out cafe-tls.key 2048

# 2. 인증서 서명 요청(CSR) 생성
openssl req -new -key cafe-tls.key -out cafe-tls.csr \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=MyOrg/OU=IT/CN=cafe.example.com"

# 3. Self-signed 인증서 생성 (1년 유효)
openssl x509 -req -days 365 -in cafe-tls.csr \
  -signkey cafe-tls.key -out cafe-tls.crt

# 4. Kubernetes Secret 생성
kubectl create secret tls cafe-tls-secret \
  --cert=cafe-tls.crt \
  --key=cafe-tls.key
```

## 🚀 2단계: 애플리케이션 배포

### TLS Secret 적용 (스크립트 사용 시)

```bash
kubectl apply -f cafe-tls-secret.yaml
```

### 애플리케이션 매니페스트 적용

```bash
kubectl apply -f cafe-app.yaml
```

## ✅ 3단계: 배포 확인

### 리소스 확인

```bash
# Pod 상태 확인
kubectl get pods

# Service 확인
kubectl get svc

# Ingress 확인
kubectl get ingress cafe-ingress

# Ingress 상세 정보
kubectl describe ingress cafe-ingress
```

### Ingress 외부 IP 확인

```bash
kubectl get ingress cafe-ingress -o wide
```

출력 예시:
```
NAME           CLASS   HOSTS              ADDRESS        PORTS     AGE
cafe-ingress   nginx   cafe.example.com   34.123.45.67   80, 443   2m
```

## 🌐 4단계: 도메인 설정

### 로컬 테스트용 hosts 파일 수정

```bash
# Ingress의 외부 IP 확인
INGRESS_IP=$(kubectl get ingress cafe-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# hosts 파일에 추가 (Linux/Mac)
echo "$INGRESS_IP cafe.example.com" | sudo tee -a /etc/hosts

# Windows의 경우
# C:\Windows\System32\drivers\etc\hosts 파일을 관리자 권한으로 열어
# <INGRESS_IP> cafe.example.com 추가
```

## 🧪 5단계: 테스트

### HTTP 테스트 (포트 80)

```bash
# Coffee 서비스
curl http://cafe.example.com/coffee

# Tea 서비스
curl http://cafe.example.com/tea
```

### HTTPS 테스트 (포트 443)

Self-signed 인증서이므로 `-k` 옵션으로 인증서 검증 무시:

```bash
# Coffee 서비스
curl -k https://cafe.example.com/coffee

# Tea 서비스
curl -k https://cafe.example.com/tea
```

### 브라우저 테스트

1. 브라우저에서 접속:
   - `http://cafe.example.com/coffee`
   - `https://cafe.example.com/tea`

2. HTTPS 접속 시 보안 경고가 나타나면:
   - Chrome: "고급" → "cafe.example.com(으)로 이동(안전하지 않음)" 클릭
   - Firefox: "고급" → "위험을 감수하고 계속" 클릭

## 📊 주요 변경 사항

### 원본 대비 변경된 부분:

1. **Service Type**: `NodePort` → `ClusterIP`
   - Ingress가 외부 접근을 처리하므로 ClusterIP로 변경

2. **Ingress 리소스 추가**:
   - HTTP(80) 및 HTTPS(443) 트래픽 라우팅
   - Path 기반 라우팅: `/coffee`, `/tea`

3. **TLS 설정**:
   - Self-signed 인증서를 사용한 HTTPS 지원
   - `cafe-tls-secret` Secret으로 인증서 관리

## 🔍 트러블슈팅

### Ingress에 외부 IP가 할당되지 않는 경우

```bash
# Ingress Controller Service 확인
kubectl get svc -n ingress-nginx

# LoadBalancer 타입이 Pending 상태라면 클라우드 환경이 아닐 수 있음
# Minikube/Kind 등 로컬 환경에서는 다음 사용:

# Minikube
minikube tunnel

# Kind (포트 포워딩 사용)
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 8443:443
# 그 후 http://localhost:8080/coffee 로 접속
```

### 인증서 오류

```bash
# Secret 확인
kubectl get secret cafe-tls-secret
kubectl describe secret cafe-tls-secret

# Secret 재생성
kubectl delete secret cafe-tls-secret
./create-tls-cert.sh
kubectl apply -f cafe-tls-secret.yaml
```

### 503 Service Unavailable 오류

```bash
# Pod 상태 확인
kubectl get pods

# Pod 로그 확인
kubectl logs -l app=coffee
kubectl logs -l app=tea

# Service 엔드포인트 확인
kubectl get endpoints coffee-svc tea-svc
```

## 🎯 프로덕션 환경 권장사항

1. **유효한 TLS 인증서 사용**:
   - Let's Encrypt (cert-manager 사용)
   - 상용 CA 인증서

2. **cert-manager 설치** (자동 인증서 관리):
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

3. **리소스 제한 설정**:
   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
     limits:
       cpu: 200m
       memory: 256Mi
   ```

4. **Health Check 추가**:
   ```yaml
   livenessProbe:
     httpGet:
       path: /
       port: 8080
   readinessProbe:
     httpGet:
       path: /
       port: 8080
   ```

## 📝 참고 사항

- Self-signed 인증서는 개발/테스트 환경에만 사용하세요
- 프로덕션 환경에서는 신뢰할 수 있는 CA의 인증서를 사용하세요
- Ingress Controller의 종류(NGINX, Traefik, HAProxy 등)에 따라 annotations가 다를 수 있습니다
- 도메인은 실제 환경에 맞게 수정하세요

## 🔗 유용한 링크

- [Kubernetes Ingress 문서](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager 문서](https://cert-manager.io/docs/)
