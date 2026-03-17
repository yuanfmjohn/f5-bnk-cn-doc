### UDP 路由

**实验性频道 (Experimental Channel)**

`UDPRoute` 资源目前仅包含在 Gateway API 的 "Experimental" 频道中。

Gateway API 旨在与多种协议配合使用，UDPRoute 是管理 UDP 流量的路径之一。F5 的 Gateway API 通过 L4Route 提供对 TCP 以及 UDP 流量的数据处理。

#### 示例

此示例包含一个 Gateway 资源和关联的一个 UDPRoute 资源，并按照以下规则分发流量:

- Gateway 端口 12345 上的所有 UDP 流都将转发到 `udp-echo-service` Kubernetes Service 的 12345 端口。

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: l4-udp-gw
  namespace: web
spec:
  addresses:
  - type: "IPAddress"
    value: 192.168.48.207
  gatewayClassName: f5-gateway-class
  listeners:
  - name: anyudp
    protocol: UDP
    port: 12345
    allowedRoutes:
      kinds:
      - kind: L4Route
        group: gateway.k8s.f5net.com
---
apiVersion: gateway.k8s.f5net.com/v1
kind: L4Route
metadata:
  name: l4-udp-app
  namespace: web
spec:
  protocol: UDP
  parentRefs:
  - name: l4-udp-gw
    sectionName: anyudp
  rules:
  - backendRefs:
    - name: udp-echo-service
      namespace: web
      port: 12345
```

在上面的示例中，我们使用 `parentRefs` 的 `sectionName` 字段将流量分离到两个独立的后端 UDP Service。这与 Gateway `listeners` 中的 `name` 直接对应。
