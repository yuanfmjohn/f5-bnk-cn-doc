## 2. HTTP 라우팅

### 2.1 기본 HTTP 라우팅

HTTPRoute 리소스를 사용하면 HTTP 트래픽을 매칭하고 Kubernetes 백엔드로 전달할 수 있습니다. 이 가이드는 HTTPRoute가 호스트, 헤더 및 경로 필드에서 트래픽을 매칭하고 다른 Kubernetes Service로 전달하는 방법을 보여줍니다.

다음 다이어그램은 세 가지 다른 Service에 걸친 필요한 트래픽 흐름을 설명합니다:

- `foo.example.com/login`으로의 트래픽은 `foo-svc`로 전달됨
- `env: canary` 헤더가 있는 `bar.example.com/*`으로의 트래픽은 `bar-svc-canary`로 전달됨
- 헤더가 없는 `bar.example.com/*`으로의 트래픽은 `bar-svc`로 전달됨

![HTTP Routing](https://gateway-api.sigs.k8s.io/images/http-routing.png)

점선은 이 라우팅 동작을 구성하기 위해 배포된 Gateway 리소스를 보여줍니다. 동일한 `prod-web` Gateway에 라우팅 규칙을 생성하는 두 개의 HTTPRoute 리소스가 있습니다.

#### Gateway와 HTTPRoute 예제:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example-gateway
spec:
  gatewayClassName: example-gateway-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
  - name: example-gateway
  hostnames:
  - "example.com"
  rules:
  - backendRefs:
    - name: example-svc
      port: 80
```

#### 호스트명 매칭

HTTPRoute는 단일 호스트명 집합과 매칭할 수 있습니다. 이러한 호스트명은 HTTPRoute 내의 다른 매칭보다 먼저 매칭됩니다.

**foo-route 예제:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: foo-route
spec:
  parentRefs:
  - name: example-gateway
  hostnames:
  - "foo.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /login
    backendRefs:
    - name: foo-svc
      port: 8080
```

이 경로는 `foo.example.com`에 대한 모든 트래픽을 매칭하고 라우팅 규칙을 적용하여 올바른 백엔드로 트래픽을 전달합니다. 하나의 매치만 지정되었으므로 `foo.example.com/login/*` 트래픽만 전달됩니다.

**bar-route 예제:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bar-route
spec:
  parentRefs:
  - name: example-gateway
  hostnames:
  - "bar.example.com"
  rules:
  - matches:
    - headers:
      - type: Exact
        name: env
        value: canary
    backendRefs:
    - name: bar-svc-canary
      port: 8080
  - backendRefs:
    - name: bar-svc
      port: 8080
```

`bar-route` HTTPRoute는 `bar.example.com`에 대한 트래픽을 매칭합니다. 이 호스트명에 대한 모든 트래픽은 라우팅 규칙에 대해 평가됩니다. 가장 구체적인 매치가 우선하므로 `env: canary` 헤더가 있는 모든 트래픽은 `bar-svc-canary`로 전달되고, 헤더가 없거나 canary가 아닌 경우 `bar-svc`로 전달됩니다.

---

### 2.2 HTTP 리다이렉트 및 리라이트

HTTPRoute 리소스는 필터를 사용하여 클라이언트에 리다이렉트를 발행하거나 업스트림으로 전송된 경로를 재작성할 수 있습니다.

**참고**: 리다이렉트 및 재작성 필터는 상호 배타적입니다. 규칙은 두 필터 유형을 동시에 사용할 수 없습니다.

#### 리다이렉트

리다이렉트는 클라이언트에 HTTP 3XX 응답을 반환하여 다른 리소스를 검색하도록 지시합니다.

##### 지원되는 상태 코드

Gateway API는 다음 HTTP 리다이렉트 상태 코드를 지원합니다:

- **301 (Moved Permanently)**: 리소스가 영구적으로 새 위치로 이동했음을 나타냅니다. HTTP에서 HTTPS로의 영구 업그레이드 또는 영구 URL 변경에 사용합니다.
- **302 (Found)**: 리소스가 일시적으로 다른 위치에서 사용 가능함을 나타냅니다. 상태 코드를 지정하지 않으면 기본값입니다.
- **303 (See Other)**: 요청에 대한 응답을 GET 메서드를 사용하여 다른 URL에서 찾을 수 있음을 나타냅니다. POST 요청 후 확인 페이지로 리다이렉트하는 데 일반적으로 사용됩니다.
- **307 (Temporary Redirect)**: 302와 유사하지만 리다이렉트를 따를 때 HTTP 메서드가 변경되지 않음을 보장합니다.
- **308 (Permanent Redirect)**: 301과 유사하지만 리다이렉트를 따를 때 HTTP 메서드가 변경되지 않음을 보장합니다.

#### HTTP에서 HTTPS로 리다이렉트

HTTP 트래픽을 HTTPS로 리다이렉트하려면 HTTP와 HTTPS 리스너가 모두 있는 Gateway가 필요합니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: redirect-gateway
  namespace: web
spec:
  addresses:
  - type: "IPAddress"
    value: 192.168.48.202
  gatewayClassName: f5-gateway-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: "All"
      kinds:
      - kind: HTTPRoute
  - name: https
    protocol: HTTPS
    port: 443
    allowedRoutes:
      namespaces:
        from: "All"
      kinds:
      - kind: HTTPRoute
    tls:
      mode: Terminate
      certificateRefs:
      - name: local-test-tls-cert
        namespace: sec-infra
        kind: Secret
        group: ""
```

HTTP 리스너에 연결하고 HTTPS로 리다이렉트하는 HTTPRoute가 필요합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-filter-redirect
  namespace: web
spec:
  parentRefs:
  - name: redirect-gateway
    sectionName: http
  hostnames:
  - www.f5bnk.com
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
  - backendRefs:
    - name: httpbin
      port: 8080
```

또한 HTTPS 트래픽을 애플리케이션 백엔드로 전달하는 HTTPS 리스너에 연결된 HTTPRoute도 필요합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-route
  namespace: web
  labels:
    gateway: redirect-gateway
spec:
  parentRefs:
  - name: redirect-gateway
    sectionName: https
  hostnames:
  - www.f5bnk.com
  rules:
  - backendRefs:
    - name: httpbin
      port: 8080
```

#### 경로 리다이렉트

경로 리다이렉트는 HTTP Path Modifier를 사용하여 전체 경로 또는 경로 접두사를 교체합니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-filter-redirect
spec:
  hostnames:
    - redirect.example
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /cayenne
      filters:
        - type: RequestRedirect
          requestRedirect:
            path:
              type: ReplaceFullPath
              replaceFullPath: /paprika
            statusCode: 302
```

`https://redirect.example/cayenne/pinch` 및 `https://redirect.example/cayenne/teaspoon`에 대한 요청은 모두 `location: https://redirect.example/paprika`가 포함된 리다이렉트를 받습니다.

#### 리라이트

리라이트는 클라이언트 요청의 구성 요소를 업스트림으로 프록시하기 전에 수정합니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-filter-rewrite
spec:
  hostnames:
    - rewrite.example
  rules:
    - filters:
        - type: URLRewrite
          urlRewrite:
            hostname: elsewhere.example
      backendRefs:
        - name: example-svc
          weight: 1
          port: 80
```

이 HTTPRoute는 `https://rewrite.example/cardamom`에 대한 요청을 수락하고 요청 헤더의 `host: rewrite.example` 대신 `host: elsewhere.example`을 사용하여 업스트림으로 `example-svc`에 전송합니다.

---

### 2.3 HTTP 헤더 수정

HTTP 헤더 수정은 들어오는 요청의 HTTP 헤더를 추가, 제거 또는 수정하는 프로세스입니다.

#### 요청 헤더 수정

**헤더 추가:**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    add:
    - name: my-header-name
      value: my-header-value
```

**헤더 수정:**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    set:
    - name: my-header-name
      value: my-new-header-value
```

**헤더 제거:**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    remove: ["x-request-id"]
```

#### 응답 헤더 수정

응답 헤더 수정은 요청 헤더 수정과 매우 유사한 구문을 사용하지만 다른 필터(`ResponseHeaderModifier`)를 사용합니다.

**여러 헤더 추가:**

```yaml
filters:
- type: ResponseHeaderModifier
  responseHeaderModifier:
    add:
    - name: X-Header-Add-1
      value: header-add-1
    - name: X-Header-Add-2
      value: header-add-2
    - name: X-Header-Add-3
      value: header-add-3
```

---

### 2.4 HTTP 트래픽 분산

HTTPRoute 리소스를 사용하면 가중치를 지정하여 다른 백엔드 간에 트래픽을 분산할 수 있습니다. 이는 롤아웃 중 트래픽 분산, 카나리 변경 또는 긴급 상황에 유용합니다.

#### 기본 트래픽 분산

다음 YAML 스니펫은 두 개의 Service가 단일 경로 규칙의 백엔드로 나열되는 방법을 보여줍니다. 이 경로 규칙은 트래픽을 `coffee-svc`에 90%, `tea-svc`에 10% 분산합니다.

![Traffic Splitting](https://gateway-api.sigs.k8s.io/images/simple-split.png)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-splitting
  namespace: web
spec:
  parentRefs:
  - name: prod-web
    sectionName: prod-web-gw
  rules:
  - backendRefs:
    - name: coffee-svc
      port: 80
      weight: 90
    - name: tea-svc
      port: 80
      weight: 10
```

`weight`는 (백분율이 아닌) 트래픽의 비례 분할을 나타내며, 단일 경로 규칙 내의 모든 가중치의 합이 모든 백엔드의 분모가 됩니다.

#### 카나리 트래픽 롤아웃

처음에는 `foo.example.com`에 대한 프로덕션 사용자 트래픽을 제공하는 Service의 단일 버전만 있을 수 있습니다. 다음 HTTPRoute는 `foo-v1` 또는 `foo-v2`에 대해 `weight`가 지정되지 않았으므로 각각의 경로 규칙과 매칭되는 트래픽의 100%를 암시적으로 수신합니다.

카나리 경로 규칙(헤더 `traffic=test` 매칭)은 프로덕션 사용자 트래픽을 `foo-v2`로 분산하기 전에 합성 테스트 트래픽을 전송하는 데 사용됩니다.

![Traffic Splitting 1](https://gateway-api.sigs.k8s.io/images/traffic-splitting-1.png)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: foo-route
  labels:
    gateway: prod-web-gw
spec:
  hostnames:
  - foo.example.com
  rules:
  - backendRefs:
    - name: foo-v1
      port: 8080
  - matches:
    - headers:
      - name: traffic
        value: test
    backendRefs:
    - name: foo-v2
      port: 8080
```

#### 블루-그린 트래픽 롤아웃

내부 테스트가 `foo-v2`로부터 성공적인 응답을 검증한 후, 점진적이고 더 현실적인 테스트를 위해 트래픽의 작은 비율을 새 Service로 전환하는 것이 바람직합니다. 다음 HTTPRoute는 `foo-v2`를 가중치와 함께 백엔드로 추가합니다.

![Traffic Splitting 2](https://gateway-api.sigs.k8s.io/images/traffic-splitting-2.png)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: foo-route
  labels:
    gateway: prod-web-gw
spec:
  hostnames:
  - foo.example.com
  rules:
  - backendRefs:
    - name: foo-v1
      port: 8080
      weight: 90
    - name: foo-v2
      port: 8080
      weight: 10
```

#### 롤아웃 완료

마지막으로 모든 신호가 긍정적이면 트래픽을 `foo-v2`로 완전히 전환하고 롤아웃을 완료할 시간입니다. `foo-v1`의 가중치를 `0`으로 설정하여 트래픽을 받지 않도록 구성합니다.

![Traffic Splitting 3](https://gateway-api.sigs.k8s.io/images/traffic-splitting-3.png)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: foo-route
  labels:
    gateway: prod-web-gw
spec:
  hostnames:
  - foo.example.com
  rules:
  - backendRefs:
    - name: foo-v1
      port: 8080
      weight: 0
    - name: foo-v2
      port: 8080
      weight: 1
```

이 시점에서 트래픽의 100%가 `foo-v2`로 라우팅되고 롤아웃이 완료됩니다. 어떤 이유로든 `foo-v2`에 오류가 발생하면 가중치를 업데이트하여 트래픽을 `foo-v1`로 빠르게 다시 전환할 수 있습니다.

---

### 2.5 HTTP 쿼리 파라미터 매칭

HTTPRoute 리소스는 쿼리 파라미터를 기반으로 요청을 매칭하는 데 사용할 수 있습니다.

다음 HTTPRoute는 `animal` 쿼리 파라미터의 값을 기반으로 두 백엔드 간에 트래픽을 분산합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: query-param-matching
  namespace: gateway-conformance-infra
spec:
  parentRefs:
  - name: same-namespace
  rules:
  - matches:
    - queryParams:
      - name: animal
        value: whale
    backendRefs:
    - name: infra-backend-v1
      port: 8080
  - matches:
    - queryParams:
      - name: animal
        value: dolphin
    backendRefs:
    - name: infra-backend-v2
      port: 8080
```

- 쿼리 파라미터 `animal=whale`이 있는 `/`에 대한 요청은 `infra-backend-v1`로 라우팅됩니다.
- 쿼리 파라미터 `animal=dolphin`이 있는 `/`에 대한 요청은 `infra-backend-v2`로 라우팅됩니다.

#### 여러 쿼리 파라미터 매칭

규칙은 여러 쿼리 파라미터와도 매칭할 수 있습니다:

```yaml
- matches:
  - queryParams:
    - name: animal
      value: dolphin
    - name: color
      value: blue
  backendRefs:
  - name: infra-backend-v3
    port: 8080
```

쿼리 파라미터 `animal=dolphin` AND `color=blue`가 있으면 `infra-backend-v3`로 트래픽이 라우팅됩니다.

---

### 2.6 HTTP 메소드 매칭

HTTPRoute 리소스는 HTTP 메소드를 기반으로 요청을 매칭하는 데 사용할 수 있습니다.

다음 HTTPRoute는 요청의 HTTP 메소드를 기반으로 두 백엔드 간에 트래픽을 분산합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: method-matching
  namespace: gateway-conformance-infra
spec:
  parentRefs:
  - name: same-namespace
  rules:
  - matches:
    - method: POST
    backendRefs:
    - name: infra-backend-v1
      port: 8080
  - matches:
    - method: GET
    backendRefs:
    - name: infra-backend-v2
      port: 8080
```

- `/`에 대한 POST 요청은 `infra-backend-v1`로 라우팅됩니다.
- `/`에 대한 GET 요청은 `infra-backend-v2`로 라우팅됩니다.

#### 다른 매치 유형과의 조합

메소드 매칭은 경로 및 헤더 매칭과 같은 다른 매치 유형과 결합될 수 있습니다:

```yaml
rules:
# 코어 매치 유형과의 조합
- matches:
  - path:
      type: PathPrefix
      value: /path1
    method: GET
  backendRefs:
  - name: infra-backend-v1
    port: 8080
- matches:
  - headers:
    - name: version
      value: one
    method: PUT
  backendRefs:
  - name: infra-backend-v2
    port: 8080
```

---