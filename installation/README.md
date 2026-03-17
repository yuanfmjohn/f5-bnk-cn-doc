# F5 BIG-IP Next for Kubernetes(BNK) 설치가이드

## 목차

1. [시작하기](#1-시작하기)
   - [간단한 Gateway 배포](#11-간단한-gateway-배포)
   - [Ingress에서 마이그레이션](#12-ingress에서-마이그레이션)

2. [HTTP 라우팅](#2-http-라우팅)
   - [기본 HTTP 라우팅](#21-기본-http-라우팅)
   - [HTTP 리다이렉트 및 리라이트](#22-http-리다이렉트-및-리라이트)
   - [HTTP 헤더 수정](#23-http-헤더-수정)
   - [HTTP 트래픽 분산](#24-http-트래픽-분산)
   - [HTTP 쿼리 파라미터 매칭](#25-http-쿼리-파라미터-매칭)
   - [HTTP 메소드 매칭](#26-http-메소드-매칭)

3. [고급 기능](#3-고급-기능)
   - [Cross-Namespace 라우팅](#31-cross-namespace-라우팅)
   - [TLS 설정](#32-tls-설정)
   - [TCP 라우팅](#33-tcp-라우팅)
   - [gRPC 라우팅](#34-grpc-라우팅)

---

## 1. 시작하기

### 1.1 간단한 Gateway 배포

Gateway API를 처음 접하는 경우 이 가이드가 시작하기 좋은 곳입니다. 가장 간단한 배포 방식인 Gateway와 Route 리소스를 동일한 소유자가 함께 배포하는 방법을 보여줍니다. 이는 Ingress에서 사용되는 모델과 유사합니다.

이 가이드에서는 모든 HTTP 트래픽을 매칭하여 `foo-svc`라는 단일 Service로 전달하는 Gateway와 HTTPRoute를 배포합니다.

![Simple Gateway](https://gateway-api.sigs.k8s.io/images/single-service-gateway.png)

**Gateway 리소스:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-web
spec:
  gatewayClassName: example
  listeners:
  - protocol: HTTP
    port: 80
    name: prod-web-gw
    allowedRoutes:
      namespaces:
        from: Same
```

Gateway는 논리적 로드 밸런서의 인스턴스화를 나타내며, GatewayClass는 사용자가 Gateway를 생성할 때 로드 밸런서 템플릿을 정의합니다. 예제 Gateway는 가상의 `example` GatewayClass에서 템플릿화되었으며, 이는 자리 표시자로 사용자가 교체해야 합니다.

사용 가능한 [Gateway Implementation](https://gateway-api.sigs.k8s.io/implementations/) 목록에서 특정 인프라 제공자에 따라 올바른 GatewayClass를 결정할 수 있습니다.

Gateway는 포트 80에서 HTTP 트래픽을 수신합니다. 이 특정 GatewayClass는 배포 후 `Gateway.status`에 표시될 IP 주소를 자동으로 할당합니다.