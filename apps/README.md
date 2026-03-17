# Cafe 애플리케이션 - HTTP/HTTPS 배포

## 🚀 빠른 시작

### 1. TLS 인증서 생성 및 적용

```bash
chmod +x create-tls-cert.sh
./create-tls-cert.sh
kubectl apply -f cafe-tls-secret.yaml
```

### 2. 애플리케이션 배포

```bash
kubectl apply -f cafe-app.yaml
```

### 3. 테스트

```bash
# HTTP (포트 80)
curl http://cafe.example.com/coffee
curl http://cafe.example.com/tea

# HTTPS (포트 443)
curl -k https://cafe.example.com/coffee
curl -k https://cafe.example.com/tea
```

## 📁 파일 구조

```
.
├── cafe-app.yaml                      # 메인 애플리케이션 매니페스트 (Ingress 포함)
├── create-tls-cert.sh                 # TLS 인증서 생성 스크립트
├── cafe-app-with-certmanager.yaml     # cert-manager 사용 버전 (프로덕션 권장)
├── DEPLOYMENT-GUIDE.md                # 상세 배포 가이드
└── README.md                          # 이 파일
```

## 📋 주요 변경사항

- ✅ Service Type: NodePort → ClusterIP
- ✅ Ingress 추가: HTTP(80) 및 HTTPS(443) 지원
- ✅ TLS/SSL: Self-signed 인증서 지원
- ✅ Path 기반 라우팅: `/coffee`, `/tea`

## 🔐 보안 참고사항

⚠️ **Self-signed 인증서는 개발/테스트용입니다!**

프로덕션 환경에서는:
- cert-manager + Let's Encrypt 사용 (`cafe-app-with-certmanager.yaml` 참조)
- 또는 상용 CA 인증서 사용

## 📖 상세 문서

전체 가이드는 [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) 참조

## 🛠️ 사전 요구사항

- Kubernetes 클러스터
- Ingress Controller (NGINX 권장)
- kubectl
- openssl

## 💡 도움말

문제가 발생하면 [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)의 트러블슈팅 섹션을 확인하세요.
