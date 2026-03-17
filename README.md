# Gateway API User Guide

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

**HTTPRoute 리소스:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: foo
spec:
  parentRefs:
  - name: prod-web
  rules:
  - backendRefs:
    - name: foo-svc
      port: 8080
```

Route 리소스는 `ParentRefs`를 사용하여 연결하려는 Gateway를 지정합니다. Gateway가 이 연결을 허용하는 한(기본적으로 동일한 네임스페이스의 Route는 신뢰됨), Route는 부모 Gateway로부터 트래픽을 수신할 수 있습니다.

이 HTTPRoute는 호스트 경로나 경로가 지정되지 않았기 때문에 로드 밸런서의 포트 80에 도착하는 모든 HTTP 트래픽을 매칭하여 `foo-svc` Pod로 전송합니다.

---

### 1.2 Ingress에서 마이그레이션

#### 주요 차이점

**1. 역할 지향적 설계**

Ingress API와 Gateway API의 주요 차이점은 역할 지향적 설계입니다.

| Ingress API | Gateway API |
|-------------|-------------|
| Ingress 컨트롤러 소유자 | 인프라 제공자 + 클러스터 운영자 |
| Ingress 소유자 | 애플리케이션 관리자 |
| N/A | 애플리케이션 개발자 |

**2. 진입점 정의**

- **Ingress**: 모든 Ingress 리소스에는 HTTP와 HTTPS 트래픽을 위한 두 개의 암묵적 진입점이 있습니다.
- **Gateway API**: 진입점은 Gateway 리소스에서 명시적으로 정의되어야 합니다.

예를 들어, 데이터 플레인이 포트 80에서 HTTP 트래픽을 처리하도록 하려면 해당 트래픽을 위한 리스너를 정의해야 합니다.

**3. TLS 종료**

- **Ingress**: TLS 섹션을 통해 TLS 종료를 지원하며, TLS 인증서와 키는 Secret에 저장됩니다.
- **Gateway API**: TLS 종료는 Gateway 리스너의 속성이며, Ingress와 유사하게 TLS 인증서와 키도 Secret에 저장됩니다.

Gateway 리소스는 클러스터 운영자와 애플리케이션 관리자가 소유하므로, 이들이 TLS 종료를 소유합니다.

**4. 라우팅 규칙**

Ingress의 경로 기반 라우팅 규칙은 HTTPRoute의 라우팅 규칙과 직접 매핑됩니다. 호스트 헤더 기반 라우팅 규칙은 HTTPRoute의 hostnames과 매핑됩니다.

HTTPRoute는 애플리케이션 개발자가 소유합니다.

---

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
spec:
  gatewayClassName: foo-lb
  listeners:
  - name: http
    protocol: HTTP
    port: 80
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - name: redirect-example
```

HTTP 리스너에 연결하고 HTTPS로 리다이렉트하는 HTTPRoute가 필요합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-filter-redirect
spec:
  parentRefs:
  - name: redirect-gateway
    sectionName: http
  hostnames:
  - redirect.example
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
```

또한 HTTPS 트래픽을 애플리케이션 백엔드로 전달하는 HTTPS 리스너에 연결된 HTTPRoute도 필요합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-route
  labels:
    gateway: redirect-gateway
spec:
  parentRefs:
  - name: redirect-gateway
    sectionName: https
  hostnames:
  - redirect.example
  rules:
  - backendRefs:
    - name: example-svc
      port: 80
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

## 3. 고급 기능

### 3.1 Cross-Namespace 라우팅

Gateway API는 Cross-Namespace 라우팅에 대한 핵심 지원을 제공합니다. 이는 여러 사용자 또는 팀이 기본 네트워킹 인프라를 공유하지만 액세스 및 장애 도메인을 최소화하기 위해 제어 및 구성을 분리해야 할 때 유용합니다.

#### 시나리오

이 가이드에는 두 개의 독립적인 팀, `store`와 `site`가 있으며, `store-ns` 및 `site-ns` 네임스페이스에서 동일한 Kubernetes 클러스터에서 운영됩니다.

**목표:**
- **site 팀**: `home` 및 `login` 두 개의 애플리케이션이 있습니다. 팀은 액세스 및 장애 도메인을 최소화하기 위해 앱 간에 액세스 및 구성을 최대한 격리하려고 합니다.
- **store 팀**: `store-ns` 네임스페이스에 배포된 `store`라는 단일 Service가 있으며, 이 또한 동일한 IP 주소와 도메인 뒤에 노출되어야 합니다.
- **인프라 팀**: `infra-ns` 네임스페이스에서 운영하며 `foo.example.com` 도메인을 제어합니다.
- **보안 팀**: `foo.example.com`에 대한 인증서를 제어합니다.

#### 공유 Gateway 배포

인프라 팀은 `shared-gateway` Gateway를 `infra-ns` 네임스페이스에 배포합니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: infra-ns
spec:
  gatewayClassName: shared-gateway-class
  listeners:
  - name: https
    hostname: "foo.example.com"
    protocol: HTTPS
    port: 443
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            shared-gateway-access: "true"
    tls:
      certificateRefs:
      - name: foo-example-com
```

이 Gateway의 `https` 리스너는 `foo.example.com` 도메인에 대한 트래픽을 매칭합니다. 또한 `infra-ns` 네임스페이스의 `foo-example-com` Secret을 사용하여 HTTPS를 구성합니다.

이 Gateway는 네임스페이스 선택기를 사용하여 어떤 HTTPRoute가 연결할 수 있는지 정의합니다:

```yaml
allowedRoutes:
  namespaces:
    from: Selector
    selector:
      matchLabels:
        shared-gateway-access: "true"
```

`shared-gateway-access: "true"` 레이블이 지정된 네임스페이스만 `shared-gateway`에 Route를 연결할 수 있습니다.

#### HTTPRoute 배포

**store 팀의 HTTPRoute:**

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: store
  namespace: store-ns
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  rules:
  - matches:
    - path:
        value: /store
    backendRefs:
    - name: store
      port: 8080
```

이 Route는 `/store` 트래픽을 매칭하여 `store` Service로 전송하는 간단한 라우팅 로직을 가지고 있습니다.

**site 팀의 HTTPRoute:**

```yaml
# home HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: home
  namespace: site-ns
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - foo.example.com
  rules:
  - backendRefs:
    - name: home
      port: 8080

---
# login HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: login
  namespace: site-ns
spec:
  parentRefs:
  - name: shared-gateway
    namespace: infra-ns
  hostnames:
  - foo.example.com
  rules:
  - matches:
    - path:
        value: /login
    backendRefs:
    - name: login-v1
      port: 8080
      weight: 90
    - name: login-v2
      port: 8080
      weight: 10
```

---

### 3.2 TLS 설정

Gateway API는 다양한 방식으로 TLS를 구성할 수 있습니다.

#### TLS 연결 유형

Gateway API는 두 가지 주요 TLS 연결을 구별합니다:

1. **downstream**: 클라이언트와 Gateway 간의 연결
2. **upstream**: Gateway와 경로에서 지정한 백엔드 리소스 간의 연결

#### 기본 TLS 구성

다음 예제에서 Gateway는 모든 요청에 대해 `default-cert` Secret 리소스에 정의된 TLS 인증서를 제공합니다:

```yaml
listeners:
- protocol: HTTPS
  port: 443
  tls:
    mode: Terminate
    certificateRefs:
    - kind: Secret
      group: ""
      name: default-cert
```

#### 호스트명별 TLS 구성

이 예제에서 Gateway는 `foo.example.com` 및 `bar.example.com` 도메인을 제공하도록 구성되어 있습니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: tls-basic
spec:
  gatewayClassName: example
  listeners:
  - name: foo-https
    protocol: HTTPS
    port: 443
    hostname: foo.example.com
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: foo-example-com-cert
  - name: bar-https
    protocol: HTTPS
    port: 443
    hostname: bar.example.com
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: bar-example-com-cert
```

#### 와일드카드 TLS 구성

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: wildcard-tls-gateway
spec:
  gatewayClassName: example
  listeners:
  - name: foo-https
    protocol: HTTPS
    port: 443
    hostname: foo.example.com
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: foo-example-com-cert
  - name: wildcard-https
    protocol: HTTPS
    port: 443
    hostname: "*.example.com"
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: wildcard-example-com-cert
```

#### Cross-Namespace 인증서 참조

이 예제에서 Gateway는 다른 네임스페이스의 인증서를 참조하도록 구성되어 있습니다. 이는 대상 네임스페이스에 생성된 ReferenceGrant에 의해 허용됩니다:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cross-namespace-tls-gateway
  namespace: gateway-api-example-ns1
spec:
  gatewayClassName: example
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "*.example.com"
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: wildcard-example-com-cert
        namespace: gateway-api-example-ns2
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-ns1-gateways-to-ref-secrets
  namespace: gateway-api-example-ns2
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: Gateway
    namespace: gateway-api-example-ns1
  to:
  - group: ""
    kind: Secret
```

---

### 3.3 TCP 라우팅

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

---

### 3.4 gRPC 라우팅

GRPCRoute 리소스를 사용하면 gRPC 트래픽을 매칭하고 Kubernetes 백엔드로 전달할 수 있습니다. 이 가이드는 GRPCRoute가 호스트, 헤더, 서비스 및 메소드 필드에서 트래픽을 매칭하고 다른 Kubernetes Service로 전달하는 방법을 보여줍니다.

#### 트래픽 흐름

다음 다이어그램은 세 가지 다른 Service에 걸친 필요한 트래픽 흐름을 설명합니다:

- `com.Example.Login` 메소드에 대한 `foo.f5bnk.com`으로의 트래픽은 `foo-svc`로 전달됨
- `env: canary` 헤더가 있는 `bar.f5bnk.com`으로의 트래픽은 모든 서비스 및 메소드에 대해 `bar-svc-canary`로 전달됨
- 헤더가 없는 `bar.f5bnk.com`으로의 트래픽은 모든 서비스 및 메소드에 대해 `bar-svc`로 전달됨

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

#### 호스트명 및 메소드 매칭

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

---

## 요약

이 문서는 Gateway API의 주요 사용자 가이드를 다룹니다:

1. **시작하기**: 간단한 Gateway 배포 및 Ingress 마이그레이션
2. **HTTP 라우팅**: 기본 라우팅, 리다이렉트/리라이트, 헤더 수정, 트래픽 분산, 쿼리 파라미터 및 메소드 매칭
3. **고급 기능**: Cross-Namespace 라우팅, TLS 설정, TCP 및 gRPC 라우팅

각 기능은 실제 사용 사례와 함께 상세한 YAML 예제를 제공하여 Gateway API의 강력하고 유연한 기능을 보여줍니다.

더 자세한 정보는 [Gateway API 공식 문서](https://gateway-api.sigs.k8s.io/)를 참조하세요.
