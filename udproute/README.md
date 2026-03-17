### UDP 라우팅

**실험적 채널**

`UDPRoute` 리소스는 현재 Gateway API의 "Experimental" 채널에만 포함되어 있습니다.

Gateway API는 여러 프로토콜과 함께 작동하도록 설계되었으며 UDPRoute는 UDP 트래픽을 관리할 수 있는 경로 중 하나입니다. F5의 Gateway API는 L4Route를 통해서 TCP 뿐만 아니라 UDP 트래픽에 대한 데이터 처리를 제공합니다.

#### 예제

이 예제에는 하나의 Gateway 리소스와 연결된 하나의 UDPRoute 리소스가 있으며 다음 규칙으로 트래픽을 분산합니다:

- Gateway의 포트 12345에 있는 모든 UDP 스트림은 `udp-echo-service` Kubernetes Service의 포트 12345으로 전달됩니다.

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

위 예제에서 `parentRefs`의 `sectionName` 필드를 사용하여 두 개의 별도 백엔드 UDP Service에 대한 트래픽을 분리합니다. 이는 Gateway의 `listeners`에 있는 `name`과 직접 대응합니다.