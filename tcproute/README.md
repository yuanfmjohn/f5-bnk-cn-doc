### TCP 라우팅

**실험적 채널**

`TCPRoute` 리소스는 현재 Gateway API의 "Experimental" 채널에만 포함되어 있습니다.

Gateway API는 여러 프로토콜과 함께 작동하도록 설계되었으며 TCPRoute는 TCP 트래픽을 관리할 수 있는 경로 중 하나입니다.

#### 예제

이 예제에는 하나의 Gateway 리소스와 두 개의 TCPRoute 리소스가 있으며 다음 규칙으로 트래픽을 분산합니다:

- Gateway의 포트 8080에 있는 모든 TCP 스트림은 `my-foo-service` Kubernetes Service의 포트 6000으로 전달됩니다.
- Gateway의 포트 8090에 있는 모든 TCP 스트림은 `my-bar-service` Kubernetes Service의 포트 6000으로 전달됩니다.

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

위 예제에서 `parentRefs`의 `sectionName` 필드를 사용하여 두 개의 별도 백엔드 TCP Service에 대한 트래픽을 분리합니다. 이는 Gateway의 `listeners`에 있는 `name`과 직접 대응합니다.