#### Kubernetes Gateway API TLS 配置 w/ F5 BIG-IP Next for Kubernetes(BNK)

> 原文文档: [TLS Configuration - Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/guides/tls/)

## 目录

- [概览](#概览)
- [客户端/服务器与 TLS](#客户端服务器与-tls)
- [Downstream TLS](#downstream-tls)
  - [Listener 与 TLS](#listener-与-tls)
  - [示例](#downstream-tls-示例)
- [Upstream TLS](#upstream-tls)
  - [TargetRef 与 TLS](#targetref-与-tls)
  - [示例](#upstream-tls-示例)
- [扩展 (Extension)](#extension)

---

## 概览

Gateway API 可以通过多种方式配置 TLS。本次测试说明了各种 TLS 设置，并提供了有效使用的指南。本次测试使用 F5 BNK 作为 Gateway，包含了除通用 Native API 之外的扩展内容。在 F5 BNK 等部分实现中，可能允许其他形式或更高级形式的 TLS 配置。

针对 Gateway，使用两种连接进行管理: 
-  downstream: 客户端与 Gateway 之间的连接。
-  upstream: Gateway 与由 route 指定的 backend 资源之间的连接。此连接指通常的 backend services 连接。 

### ⚠️ Experimental Channel

下方说明的 `TLSRoute` 资源目前仅包含在 Gateway API 的 "Experimental" 频道中。有关 release 频道的详细信息，请参阅 [版本指南 (versioning guide)](https://gateway-api.sigs.k8s.io/concepts/versioning/)。

---

## 客户端/服务器与 TLS

针对 Gateway，涉及两种连接：

- **downstream**: 客户端与 Gateway 之间的连接。
- **upstream**: Gateway 与由 route 指定的 backend 资源之间的连接。这些 backend 资源通常是 Service。

使用 Gateway API，downstream 和 upstream 连接的 TLS 配置是独立管理的。

### Downstream 连接的 Listener Protocol 和 TLS Mode

对于 downstream 连接，根据 Listener Protocol 支持不同的 TLS mode 和 Route type。

| Listener Protocol | TLS Mode | Route Type Supported |
|-------------------|----------|---------------------|
| TLS | Passthrough | TLSRoute |
| TLS | Terminate | TLSRoute (extended) |
| HTTPS | Terminate | HTTPRoute |
| GRPC | Terminate | GRPCRoute |

> **备注**: 对于 `Passthrough` TLS mode，来自客户端的 TLS 会话不会在 Gateway 终止，而是以加密状态通过 Gateway，因此不会应用 TLS 设置。

### Upstream 连接

对于 upstream 连接，使用 `BackendTLSPolicy`，并且 listener protocol 或 TLS mode 不会应用于 upstream TLS 配置。对于 `HTTPRoute`，支持同时使用 `Terminate` TLS mode 和 `BackendTLSPolicy`。将它们结合使用可以提供通常所说的在 Gateway 终止并重新加密的连接。

在 `TLSRoute` 中使用 `Terminate` 可以在 `Extended` [Support Level](https://gateway-api.sigs.k8s.io/concepts/conformance/#2-support-levels) 中使用。

---

## Downstream TLS

Downstream TLS 设置是在 Gateway 级别使用 listener 配置的。

### Listener 与 TLS

Listener 按域名或子域名公开 TLS 设置。listener 的 TLS 设置应用于满足 `hostname` 标准的所有域名。

在以下示例中，Gateway 为所有请求提供 `default-cert` Secret 资源中定义的 TLS 证书。示例虽然引用了 HTTPS 协议，但同样的功能也可以用于带有 TLSRoute 的 TLS 专用协议。

```yaml
listeners:
- protocol: HTTPS # 其他可能的值为 `TLS`
  port: 443
  tls:
    mode: Terminate # 如果 protocol 是 `TLS`，`Passthrough` 是可选模式
    certificateRefs:
    - kind: Secret
      group: ""
      name: default-cert
```

### Downstream TLS 示例

#### 1. 拥有不同证书的 Listener

在此示例中，F5 BNK Gateway 被配置为提供 `coffee.f5bnk.com` 和 `tea.f5bnk.com` 域名。这些域名的证书在 Gateway 中指定。

创建一个将特定 URL 的 POST 方法转换为 GET 请求的 HTTP Route。

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

在此示例中，Gateway 配置了针对 `*.example.com` 的通配符证书和针对 `coffee.f5bnk.com` 的另一个证书。由于特定匹配优先，Gateway 会为 `coffee.f5bnk.com` 的请求提供 `coffee-f5bnk-com-cert`，为其他所有请求提供 `wildcard-f5bnk-com-cert`。

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

#### 3. 跨命名空间 (Cross Namespace) 证书引用

在此示例中，Gateway 被配置为引用其他命名空间的证书。这是通过在目标命名空间中创建的 ReferenceGrant 允许的。如果没有该 ReferenceGrant，跨命名空间引用将失效。

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

测试结果 (curl)

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
* HTTP 1.0 connection set to keep alive
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
* HTTP 1.0 connection set to keep alive
< Connection: Keep-Alive
< Content-Length: 0
<
* Connection #0 to host www.f5bnk.com left intact
* Maximum (1) redirects followed
```

对 `http://www.f5bnk.com/latte/coffee` 使用 POST 方法发起的请求将转换为 `http://www.f5bnk.com/black/tea` 的 GET 请求并进行重定向。


---

## Upstream TLS

Upstream TLS 设置是通过 target reference 连接到 `Service` 的 `BackendTLSPolicy` 配置的。

该资源可用于描述 Gateway 在连接到 backend 时应使用的 SNI，以及应如何验证 backend Pod(s) 提供的证书。

### TargetRef 与 TLS

BackendTLSPolicy 包含关于 `TargetRefs` 和 `Validation` 的规范：

- **TargetRefs**: 必需，标识 HTTPRoute 需要 TLS 的一个或多个 `Service`。
- **Validation**: 必需，包含 `Hostname` 和 `CACertificateRefs` 或 `WellKnownCACertificates` 之一。

#### Hostname

表示 Gateway 连接到 backend 时应使用的 SNI，必须与 backend pod 提供的证书匹配。

#### CACertificateRefs

引用一个或多个 PEM 编码的 TLS 证书。如果没有特定的证书可供使用，应将 WellKnownCACertificates 设置为 "System"，使 Gateway 使用一组受信任的 CA 证书。

> **备注**: 每个实现中使用的系统证书可能会有细微差别。详情请参阅所选实现的文档。

#### 限制事项

- ❌ 不允许跨命名空间 (Cross-namespace) 证书引用。
- ❌ 不允许使用通配符域名 (Wildcard hostname)。

### Upstream TLS 示例

#### 1. 使用系统证书 (System Certificate)

在此示例中，`BackendTLSPolicy` 被配置为使用系统证书，以便连接到由 `dev` Service 支持的 Pod。预计 Pod 将为 TLS 加密的 upstream 连接提供 `dev.example.com` 的有效证书。

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

#### 2. 使用显式 CA 证书

在此示例中，`BackendTLSPolicy` 被配置为使用配置映射 (configuration map) `auth-cert` 中定义的证书，以便连接到由 `auth` Service 支持的 Pod。预计 Pod 将为 TLS 加密的 upstream 连接提供 `auth.example.com` 的有效证书。

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

## 扩展 (Extension)

Gateway TLS 配置提供了一个 `options` 映射，用于添加针对特定实现的额外 TLS 设置。 

此处可能包含的功能示例：
- TLS 版本限制
- 要使用的加密算法 (cipher)

---

## 参考资料

- [Kubernetes Gateway API 官方文档](https://gateway-api.sigs.k8s.io/)
- [Gateway API Versioning Guide](https://gateway-api.sigs.k8s.io/concepts/versioning/)
- [Conformance and Support Levels](https://gateway-api.sigs.k8s.io/concepts/conformance/)

---
