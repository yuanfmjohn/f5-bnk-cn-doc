#### Kubernetes Gateway API TLS 구성 w/ F5 BIG-IP Next for Kubernetes(BNK)

> 원본 문서: [TLS Configuration - Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/guides/tls/)

## 목차

- [개요](#개요)
- [Client/Server와 TLS](#clientserver와-tls)
- [Downstream TLS](#downstream-tls)
  - [Listener와 TLS](#listener와-tls)
  - [예제](#downstream-tls-예제)
- [Upstream TLS](#upstream-tls)
  - [TargetRef와 TLS](#targetref와-tls)
  - [예제](#upstream-tls-예제)
- [Extension](#extension)

---

## 개요

Gateway API는 다양한 방법으로 TLS를 구성할 수 있습니다. 이 테스트에서는 다양한 TLS 설정을 설명하고 효과적으로 사용하는 가이드 라인을 제공합니다. 이 테스트에서는 Gateway를 F5 BNK를 사용하였으며, 일반적인 Native API외 확장된 내용을 포함하고 있습니다. F5 BNK와 같은 일부 구현체에서는 다른 형태 또는 더 고급 형태의 TLS 구성을 허용할 수 있습니다.

Gateway의 경우 2가지 연결을 사용하여 관리합니다. 
-  downstream: 클라이언트와 Gateway 사이의 연결입니다.
-  upstream: Gateway와 route에 의해 지정된 backend 리소스 사이의 연결입니다. 이 연결이 일반적인 backend services 연결을 의미합니다. 

### ⚠️ Experimental Channel

아래에 설명된 `TLSRoute` 리소스는 현재 Gateway API의 "Experimental" 채널에만 포함되어 있습니다. release 채널에 대한 자세한 내용은 [versioning guide](https://gateway-api.sigs.k8s.io/concepts/versioning/)를 참조하세요.

---

## Client/Server와 TLS

Gateway의 경우 두 가지 연결이 관련됩니다:

- **downstream**: 클라이언트와 Gateway 사이의 연결입니다.
- **upstream**: Gateway와 route에 의해 지정된 backend 리소스 사이의 연결입니다. 이러한 backend 리소스는 일반적으로 Service입니다.

Gateway API를 사용하면 downstream 및 upstream 연결의 TLS 구성이 독립적으로 관리됩니다.

### Downstream 연결의 Listener Protocol과 TLS Mode

downstream 연결의 경우, Listener Protocol에 따라 다른 TLS mode와 Route type이 지원됩니다.

| Listener Protocol | TLS Mode | Route Type Supported |
|-------------------|----------|---------------------|
| TLS | Passthrough | TLSRoute |
| TLS | Terminate | TLSRoute (extended) |
| HTTPS | Terminate | HTTPRoute |
| GRPC | Terminate | GRPCRoute |

> **참고**: `Passthrough` TLS mode의 경우, 클라이언트로부터의 TLS 세션이 Gateway에서 종료되지 않고 암호화된 상태로 Gateway를 통과하기 때문에 TLS 설정이 적용되지 않습니다.

### Upstream 연결

upstream 연결의 경우, `BackendTLSPolicy`가 사용되며, listener protocol이나 TLS mode는 upstream TLS 구성에 적용되지 않습니다. `HTTPRoute`의 경우, `Terminate` TLS mode와 `BackendTLSPolicy`를 함께 사용하는 것이 지원됩니다. 이들을 함께 사용하면 일반적으로 Gateway에서 종료되고 재암호화되는 연결로 알려진 것을 제공합니다.

`TLSRoute`에서 `Terminate`의 사용은 `Extended` [Support Level](https://gateway-api.sigs.k8s.io/concepts/conformance/#2-support-levels)에서 사용 가능합니다.

---

## Downstream TLS

Downstream TLS 설정은 Gateway 레벨에서 listener를 사용하여 구성됩니다.

### Listener와 TLS

Listener는 도메인 또는 서브도메인별로 TLS 설정을 노출합니다. listener의 TLS 설정은 `hostname` 기준을 만족하는 모든 도메인에 적용됩니다.

다음 예제에서 Gateway는 모든 요청에 대해 `default-cert` Secret 리소스에 정의된 TLS 인증서를 제공합니다. 예제는 HTTPS 프로토콜을 참조하지만, TLSRoute와 함께 TLS 전용 프로토콜에도 동일한 기능을 사용할 수 있습니다.

```yaml
listeners:
- protocol: HTTPS # 다른 가능한 값은 `TLS`
  port: 443
  tls:
    mode: Terminate # protocol이 `TLS`인 경우, `Passthrough`가 가능한 mode
    certificateRefs:
    - kind: Secret
      group: ""
      name: default-cert
```

### Downstream TLS 예제

#### 1. 다른 인증서를 가진 Listener

이 예제에서 F5 BNK Gateway는 `coffee.f5bnk.com` 및 `tea.f5bnk.com` 도메인을 제공하도록 구성되어 있습니다. 이러한 도메인에 대한 인증서는 Gateway에서 지정됩니다.

POST Method을 사용하는 특정 URL에 대해서 GET 요청으로 변환하는 HTTP Route를 생성합니다.

```yaml
aapiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: tls-basic
spec:
  gatewayClassName: f5bnk.com
  listeners:
  - name: coffee-https
    protocol: HTTPS
    port: 443
    hostname: coffee.f5bnk.com
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: coffee-f5bnk-com-cert
  - name: tea-https
    protocol: HTTPS
    port: 443
    hostname: tea.f5bnk.com
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: tea-f5bnk-com-cert
```

#### 2. Wildcard TLS Listener

이 예제에서 Gateway는 `*.example.com`에 대한 wildcard 인증서와 `coffee.f5bnk.com`에 대한 다른 인증서로 구성되어 있습니다. 특정 일치가 우선하므로 Gateway는 `coffee.f5bnk.com`에 대한 요청에는 `coffee-f5bnk-com-cert`를 제공하고 다른 모든 요청에는 `wildcard-f5bnk-com-cert`를 제공합니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: wildcard-tls-gw
  namespace: web
spec:
  addresses:
  - type: "IPAddress"
    value: 192.168.48.222
  gatewayClassName: f5-gateway-class
  listeners:
  - name: coffee-https
    protocol: HTTPS
    port: 443
    hostname: "coffee.f5bnk.com"
    tls:
      certificateRefs:
      - kind: Secret
        namespace: web
        group: ""
        name: coffee-f5bnk-com-cert
    allowedRoutes:
      namespaces:
        from: "All"
      kinds:
      - kind: HTTPRoute
  - name: wildcard-https
    protocol: HTTPS
    port: 443
    hostname: "*.f5bnk.com"
    tls:
      certificateRefs:
      - kind: Secret
        namespace: sec-infra
        group: ""
        name: wildcard-f5bnk-com-cert
    allowedRoutes:
      namespaces:
        from: "All"
      kinds:
      - kind: HTTPRoute
```

#### 3. Cross Namespace 인증서 참조

이 예제에서 Gateway는 다른 namespace의 인증서를 참조하도록 구성되어 있습니다. 이는 대상 namespace에서 생성된 ReferenceGrant에 의해 허용됩니다. 해당 ReferenceGrant가 없으면 cross-namespace 참조는 유효하지 않습니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cross-namespace-tls-gw
  namespace: f5-bnk
spec:
  gatewayClassName: f5-gateway-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "*.f5bnk.com"
    tls:
      certificateRefs:
      - kind: Secret
        group: ""
        name: wildcard-f5bnk-com-cert
        namespace: f5-bnk
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-to-secret
  namespace: sec-infra
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: web
  to:
    - group: ""
      kind: Secret
```


```

테스트 결과(curl)

```shell
» curl -sk -L --resolve www.f5bnk.com:80:192.168.48.202 -X POST -d "abc" http://www.f5bnk.com/latte/coffee -vvv --max-redirs 1                                ~
* Added www.f5bnk.com:80:192.168.48.202 to DNS cache
* Hostname www.f5bnk.com was found in DNS cache
*   Trying 192.168.48.202:80...
* Connected to www.f5bnk.com (192.168.48.202) port 80
> POST /latte/coffee HTTP/1.1
> Host: www.f5bnk.com
> User-Agent: curl/8.5.0
> Accept: */*
> Content-Length: 3
> Content-Type: application/x-www-form-urlencoded
>
* HTTP 1.0, assume close after body
< HTTP/1.0 303 See Other
* Please rewind output before next send
< Location: http://www.f5bnk.com/black/tea
< Server: BigIP
* HTTP/1.0 connection set to keep alive
< Connection: Keep-Alive
< Content-Length: 0
<
* Connection #0 to host www.f5bnk.com left intact
* Issue another request to this URL: 'http://www.f5bnk.com/black/tea'
* Switch to GET
* Found bundle for host: 0x6000021ccd50 [serially]
* Can not multiplex, even if we wanted to
* Re-using existing connection with host www.f5bnk.com
> POST /black/tea HTTP/1.0
> Host: www.f5bnk.com
> User-Agent: curl/8.5.0
> Accept: */*
>
* HTTP 1.0, assume close after body
< HTTP/1.0 303 See Other
< Location: http://www.f5bnk.com/black/tea
< Server: BigIP
* HTTP/1.0 connection set to keep alive
< Connection: Keep-Alive
< Content-Length: 0
<
* Connection #0 to host www.f5bnk.com left intact
* Maximum (1) redirects followed
```

`http://www.f5bnk.com/latte/coffee` 및 POST Method를 사용한 요청은 `http://www.f5bnk.com/black/tea` GET 요청으로 변환하여 Redirect 합니다.


---

## Upstream TLS

Upstream TLS 설정은 target reference를 통해 `Service`에 연결된 `BackendTLSPolicy`를 사용하여 구성됩니다.

이 리소스는 Gateway가 backend에 연결할 때 사용해야 하는 SNI와 backend Pod(s)에서 제공하는 인증서가 어떻게 검증되어야 하는지를 설명하는 데 사용할 수 있습니다.

### TargetRef와 TLS

BackendTLSPolicy는 `TargetRefs`와 `Validation`에 대한 명세를 포함합니다:

- **TargetRefs**: 필수이며 HTTPRoute가 TLS를 필요로 하는 하나 이상의 `Service`를 식별합니다.
- **Validation**: 필수 `Hostname`과 `CACertificateRefs` 또는 `WellKnownCACertificates` 중 하나를 포함합니다.

#### Hostname

Gateway가 backend에 연결할 때 사용해야 하는 SNI를 나타내며, backend pod에서 제공하는 인증서와 일치해야 합니다.

#### CACertificateRefs

하나 이상의 PEM으로 인코딩된 TLS 인증서를 참조합니다. 사용할 특정 인증서가 없는 경우, WellKnownCACertificates를 "System"으로 설정하여 Gateway가 신뢰할 수 있는 CA 인증서 세트를 사용하도록 해야 합니다.

> **참고**: 각 구현체에서 사용되는 시스템 인증서에는 약간의 차이가 있을 수 있습니다. 자세한 내용은 선택한 구현체의 문서를 참조하세요.

#### 제한사항

- ❌ Cross-namespace 인증서 참조는 허용되지 않습니다.
- ❌ Wildcard hostname은 허용되지 않습니다.

### Upstream TLS 예제

#### 1. System Certificate 사용

이 예제에서 `BackendTLSPolicy`는 `dev` Service를 지원하는 Pod가 `dev.example.com`에 대한 유효한 인증서를 제공할 것으로 예상되는 TLS로 암호화된 upstream 연결에 연결하기 위해 시스템 인증서를 사용하도록 구성되어 있습니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: BackendTLSPolicy
metadata:
  name: tls-upstream-dev
spec:
  targetRefs:
    - kind: Service
      name: dev
      group: ""
  validation:
    wellKnownCACertificates: "System"
    hostname: dev.example.com
```

#### 2. 명시적 CA Certificate 사용

이 예제에서 `BackendTLSPolicy`는 `auth` Service를 지원하는 Pod가 `auth.example.com`에 대한 유효한 인증서를 제공할 것으로 예상되는 TLS로 암호화된 upstream 연결에 연결하기 위해 configuration map `auth-cert`에 정의된 인증서를 사용하도록 구성되어 있습니다.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: BackendTLSPolicy
metadata:
  name: tls-upstream-auth
spec:
  targetRefs:
    - kind: Service
      name: auth
      group: ""
  validation:
    caCertificateRefs:
      - kind: ConfigMap
        name: auth-cert
        group: ""
    hostname: auth.example.com
```

---

## Extension

Gateway TLS 구성은 구현별 기능에 대한 추가 TLS 설정을 추가하기 위한 `options` map을 제공합니다. 

여기에 포함될 수 있는 기능의 예:
- TLS 버전 제한
- 사용할 암호화 방식(cipher)

---

## 참고 자료

- [Kubernetes Gateway API 공식 문서](https://gateway-api.sigs.k8s.io/)
- [Gateway API Versioning Guide](https://gateway-api.sigs.k8s.io/concepts/versioning/)
- [Conformance and Support Levels](https://gateway-api.sigs.k8s.io/concepts/conformance/)

---