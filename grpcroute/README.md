### gRPC 路由

使用 GRPCRoute 资源，您可以匹配 gRPC 流量并将其转发到 Kubernetes 后端。本指南展示了 GRPCRoute 如何在主机、标头、服务和方法字段中匹配流量，并将其转发到不同的 Kubernetes Service。

#### 流量流

下图说明了跨三个不同 Service 的所需流量流
![gRPC Route Flow](https://github.com/f5minions/f5-bnk/blob/kakao-poc-preparation/images/3.8_grpc_route.png)

- `grpc.f5bnk.com` 请求将流量发送到后端 `go-grpc-greeter-server`
- gRPC Gateway 利用存储在其他命名空间 (`sec-infra`) 的证书来实现基于 HTTP/2 的 TLS 加密集成
- 后端 gRPC 服务器基于未加密的明文 (plaintext) 与 F5 BNK Gateway 进行通信

#### Gateway 及 GRPCRoute 示例

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

#### 主机名与方法匹配 [需要进一步测试]

**foo-route 示例：**

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

此路由匹配发往 `foo.example.com` 的所有流量并应用路由规则。由于仅指定了一个匹配项，因此仅转发对 `com.example.User.Login` 方法的请求。

**bar-route 示例：**

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

`bar-route` GRPCRoute 匹配发往 `bar.example.com` 的 RPC。由于最具体的匹配优先，因此所有带有 `env: canary` 标头的流量都将转发到 `bar-svc-canary`，如果没有该标头或值不是 canary，则转发到 `bar-svc`。
