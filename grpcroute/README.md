### gRPC 라우팅

GRPCRoute 리소스를 사용하면 gRPC 트래픽을 매칭하고 Kubernetes 백엔드로 전달할 수 있습니다. 이 가이드는 GRPCRoute가 호스트, 헤더, 서비스 및 메소드 필드에서 트래픽을 매칭하고 다른 Kubernetes Service로 전달하는 방법을 보여줍니다.

#### 트래픽 흐름

다음 다이어그램은 세 가지 다른 Service에 걸친 필요한 트래픽 흐름을 설명합니다
![gRPC Route Flow](https://github.com/f5minions/f5-bnk/blob/kakao-poc-preparation/images/3.8_grpc_route.png)

- `grpc.f5bnk.com` 요청은 Backend `go-grpc-greeter-server`로 트래픽을 전송
- gRPC Gateway는 HTTP/2 기반의 TLS 암호화를 위해 다른 네임스페이스(`sec-infra`)에 저장된 인증서를 활용하여 연동
- Backend gRPC 서버는 암호화되지 않은 plaintext 기반으로 F5 BNK Gateway와 통신

#### Gateway 및 GRPCRoute 예제

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: grpc-gw
  namespace: web
spec:
  addresses:
  - type: "IPAddress"
    value: 192.168.48.209
  gatewayClassName: f5-gateway-class
  listeners:
  - name: grpc
    protocol: HTTPS
    port: 50051
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: local-test-tls-cert
        namespace: sec-infra
    allowedRoutes:
      namespaces:
        from: "All"
      kinds:
      - kind: GRPCRoute 
---
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: grpc-route
  namespace: web 
spec:
  parentRefs:
  - name: grpc-gw
    sectionName: grpc 
  rules:
  - backendRefs:
    - name: go-grpc-greeter-server
      namespace: web 
      port: 50051
```

#### 호스트명 및 메소드 매칭 [추가 테스트필요]

**foo-route 예제:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: foo-route
spec:
  parentRefs:
  - name: example-gateway
  hostnames:
  - "foo.f5bnk.com"
  rules:
  - matches:
    - method:
        service: com.example.User
        method: Login
    backendRefs:
    - name: foo-svc
      port: 50051
```

이 경로는 `foo.example.com`에 대한 모든 트래픽을 매칭하고 라우팅 규칙을 적용합니다. 하나의 매치만 지정되었으므로 `com.example.User.Login` 메소드에 대한 요청만 전달됩니다.

**bar-route 예제:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: bar-route
spec:
  parentRefs:
  - name: example-gateway
  hostnames:
  - "bar.f5bnk.com"
  rules:
  - matches:
    - headers:
      - type: Exact
        name: env
        value: canary
    backendRefs:
    - name: bar-svc-canary
      port: 50051
  - backendRefs:
    - name: bar-svc
      port: 50051
```

`bar-route` GRPCRoute는 `bar.example.com`에 대한 RPC를 매칭합니다. 가장 구체적인 매치가 우선하므로 `env: canary` 헤더가 있는 모든 트래픽은 `bar-svc-canary`로 전달되고, 헤더가 없거나 값이 canary가 아닌 경우 `bar-svc`로 전달됩니다.