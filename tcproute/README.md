### TCP 路由

**实验性频道（Experimental Channel）**

`TCPRoute` 资源目前仅包含在 Gateway API 的 "Experimental" 频道中。

Gateway API 旨在与多种协议配合工作，而 TCPRoute 是管理 TCP 流量的路径之一。

#### 示例

本示例包含一个 Gateway 资源和两个 TCPRoute 资源，并按照以下规则分配流量：

- Gateway 8080 端口上的所有 TCP 流都转发到 `my-foo-service` Kubernetes Service 的 6000 端口。
- Gateway 8090 端口上的所有 TCP 流都转发到 `my-bar-service` Kubernetes Service 的 6000 端口。

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-tcp-gateway
spec:
  gatewayClassName: my-tcp-gateway-class
  listeners:
  - name: foo
    protocol: TCP
    port: 8080
    allowedRoutes:
      kinds:
      - kind: TCPRoute
  - name: bar
    protocol: TCP
    port: 8090
    allowedRoutes:
      kinds:
      - kind: TCPRoute
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: tcp-app-1
spec:
  parentRefs:
  - name: my-tcp-gateway
    sectionName: foo
  rules:
  - backendRefs:
    - name: my-foo-service
      port: 6000
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: tcp-app-2
spec:
  parentRefs:
  - name: my-tcp-gateway
    sectionName: bar
  rules:
  - backendRefs:
    - name: my-bar-service
      port: 6000
```

在上面的示例中，我们使用 `parentRefs` 的 `sectionName` 字段将流量分离到两个独立的后端 TCP Service。这与 Gateway `listeners` 中的 `name` 直接对应。
