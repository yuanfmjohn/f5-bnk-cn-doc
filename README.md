# Gateway API 用户指南

## 目录

1. [开始使用](#1-开始使用)
   - [简单的 Gateway 部署](#11-简单的-gateway-部署)
   - [从 Ingress 迁移](#12-从-ingress-迁移)

2. [HTTP 路由](#2-http-路由)
   - [基础 HTTP 路由](#21-基础-http-路由)
   - [HTTP 重定向与重写](#22-http-重定向与重写)
   - [修改 HTTP 标头](#23-修改-http-标头)
   - [HTTP 流量拆分](#24-http-流量拆分)
   - [HTTP 查询参数匹配](#25-http-查询参数匹配)
   - [HTTP 方法匹配](#26-http-方法匹配)

3. [高级功能](#3-高级功能)
   - [跨命名空间（Cross-Namespace）路由](#31-跨命名空间路由)
   - [TLS 设置](#32-tls-设置)
   - [TCP 路由](#33-tcp-路由)
   - [gRPC 路由](#34-grpc-路由)

---

## 1. 开始使用

### 1.1 简单的 Gateway 部署

如果您是第一次接触 Gateway API，本指南是一个很好的起点。它展示了最简单的部署方式：由同一所有者共同部署 Gateway 和 Route 资源。这与 Ingress 使用的模型类似。

在本指南中，我们将部署一个 Gateway 和一个 HTTPRoute，用于匹配所有 HTTP 流量并将其转发到名为 `foo-svc` 的单个 Service。

![Simple Gateway](https://gateway-api.sigs.k8s.io/images/single-service-gateway.png)

**Gateway 资源：**

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

Gateway 表示逻辑负载均衡器的实例化，而 GatewayClass 定义了用户创建 Gateway 时的负载均衡器模板。示例中的 Gateway 是基于虚拟的 `example` GatewayClass 模板化的，用户应将其替换为实际的值。

您可以从可用的 [Gateway Implementation](https://gateway-api.sigs.k8s.io/implementations/) 列表中，根据特定的基础架构提供商确定正确的 GatewayClass。

Gateway 在 80 端口接收 HTTP 流量。这个特定的 GatewayClass 会自动分配一个 IP 地址，该地址在部署后将显示在 `Gateway.status` 中。

**HTTPRoute 资源：**

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

Route 资源使用 `ParentRefs` 指定要连接的 Gateway。只要 Gateway 允许此连接（默认情况下信任同一命名空间中的 Route），Route 就可以从父级 Gateway 接收流量。

由于此 HTTPRoute 未指定主机路径或路径，它将匹配到达负载均衡器 80 端口的所有 HTTP 流量，并将其发送到 `foo-svc` Pod。

---

### 1.2 从 Ingress 迁移

#### 主要区别

**1. 面向角色的设计**

Ingress API 与 Gateway API 之间的主要区别在于面向角色的设计。

| Ingress API | Gateway API |
|-------------|-------------|
| Ingress 控制器所有者 | 基础架构提供商 + 集群运营商 |
| Ingress 所有者 | 应用管理员 |
| N/A | 应用开发人员 |

**2. 入口点定义**

- **Ingress**：每个 Ingress 资源都有两个用于 HTTP 和 HTTPS 流量的隐式入口点。
- **Gateway API**：入口点必须在 Gateway 资源中显式定义。

例如，如果您希望数据平面处理 80 端口上的 HTTP 流量，则必须为该流量定义一个监听器。

**3. TLS 终止**

- **Ingress**：通过 TLS 部分支持 TLS 终止，TLS 证书和密钥存储在 Secret 中。
- **Gateway API**：TLS 终止是 Gateway 监听器的属性，与 Ingress 类似，TLS 证书和密钥也存储在 Secret 中。

由于 Gateway 资源由集群运营商和应用管理员所有，因此他们拥有 TLS 终止的所有权。

**4. 路由规则**

Ingress 中基于路径的路由规则直接映射到 HTTPRoute 的路由规则。基于 Host 标头的路由规则映射到 HTTPRoute 的 hostnames。

HTTPRoute 由应用开发人员所有。

---

## 2. HTTP 路由

### 2.1 基础 HTTP 路由

使用 HTTPRoute 资源，您可以匹配 HTTP 流量并将其转发到 Kubernetes 后端。本指南展示了 HTTPRoute 如何在主机、标头和路径字段中匹配流量，并将其转发到不同的 Kubernetes Service。

下图说明了跨三个不同 Service 的所需流量流：

- 发往 `foo.example.com/login` 的流量转发到 `foo-svc`
- 带有 `env: canary` 标头发往 `bar.example.com/*` 的流量转发到 `bar-svc-canary`
- 不带标头发往 `bar.example.com/*` 的流量转发到 `bar-svc`

![HTTP Routing](https://gateway-api.sigs.k8s.io/images/http-routing.png)

虚线显示了为配置此路由行为而部署的 Gateway 资源。有两个 HTTPRoute 资源在同一个 `prod-web` Gateway 上创建路由规则。

#### Gateway 与 HTTPRoute 示例：

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

#### 主机名匹配

HTTPRoute 可以匹配单个主机名集。这些主机名会先于 HTTPRoute 内的其他匹配进行匹配。

**foo-route 示例：**

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

此路由匹配发往 `foo.example.com` 的所有流量，并应用路由规则将流量转发到正确的后端。由于仅指定了一个匹配项，因此仅转发 `foo.example.com/login/*` 流量。

**bar-route 示例：**

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

`bar-route` HTTPRoute 匹配发往 `bar.example.com` 的流量。该主机名的所有流量都将针对路由规则进行评估。由于最具体的匹配优先，因此所有带有 `env: canary` 标头的流量都将转发到 `bar-svc-canary`，如果没有该标头或值不是 canary，则转发到 `bar-svc`。

---

### 2.2 HTTP 重定向与重写

HTTPRoute 资源可以使用过滤器向客户端发出重定向，或修改发送到上游的路径。

**注意**：重定向和重写过滤器是互斥的。规则不能同时使用这两种过滤器类型。

#### 重定向

重定向向客户端返回 HTTP 3XX 响应，指示其检索其他资源。

##### 支持的状态码

Gateway API 支持以下 HTTP 重定向状态码：

- **301 (Moved Permanently)**：表示资源已永久移动到新位置。用于将 HTTP 永久升级为 HTTPS 或永久更改 URL。
- **302 (Found)**：表示资源临时位于其他位置。如果未指定状态码，则此为默认值。
- **303 (See Other)**：表示可以使用 GET 方法在另一个 URL 找到对请求的响应。通常用于 POST 请求后重定向到确认页面。
- **307 (Temporary Redirect)**：类似于 302，但保证在跟随重定向时 HTTP 方法不会改变。
- **308 (Permanent Redirect)**：类似于 301，但保证在跟随重定向时 HTTP 方法不会改变。

#### 从 HTTP 重定向到 HTTPS

要将 HTTP 流量重定向到 HTTPS，需要一个同时具有 HTTP 和 HTTPS 监听器的 Gateway。

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

需要一个连接到 HTTP 监听器并重定向到 HTTPS 的 HTTPRoute：

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

此外，还需要一个连接到 HTTPS 监听器的 HTTPRoute，用于将 HTTPS 流量转发到应用后端：

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

#### 路径重定向

路径重定向使用 HTTP Path Modifier 替换整个路径或路径前缀。

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

对 `https://redirect.example/cayenne/pinch` 和 `https://redirect.example/cayenne/teaspoon` 的请求都将收到包含 `location: https://redirect.example/paprika` 的重定向。

#### 重写

重写在将客户端请求代理到上游之前修改其组件。

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

此 HTTPRoute 接受发往 `https://rewrite.example/cardamom` 的请求，并在发送到上游 `example-svc` 时，将请求标头中的 `host: rewrite.example` 替换为 `host: elsewhere.example`。

---

### 2.3 修改 HTTP 标头

修改 HTTP 标头是添加、删除或修改传入请求或传出响应的 HTTP 标头的过程。

#### 修改请求标头

**添加标头：**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    add:
    - name: my-header-name
      value: my-header-value
```

**修改标头：**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    set:
    - name: my-header-name
      value: my-new-header-value
```

**删除标头：**

```yaml
filters:
- type: RequestHeaderModifier
  requestHeaderModifier:
    remove: ["x-request-id"]
```

#### 修改响应标头

修改响应标头使用与修改请求标头非常相似的语法，但使用不同的过滤器（`ResponseHeaderModifier`）。

**添加多个标头：**

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

### 2.4 HTTP 流量拆分

使用 HTTPRoute 资源，您可以通过指定权重在不同的后端之间拆分流量。这在滚动更新期间的流量分配、金丝雀发布或紧急情况下非常有用。

#### 基础流量拆分

以下 YAML 片段展示了如何在单个路由规则中列出两个 Service 作为后端。此路由规则将 90% 的流量分配给 `coffee-svc`，10% 分配给 `tea-svc`。

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

`weight` 表示流量的比例拆分（而非百分比），单个路由规则内所有权重的总和将成为所有后端的分母。

#### 金丝雀流量滚动更新

最初，可能只有一个版本的 Service 为 `foo.example.com` 提供生产用户流量。以下 HTTPRoute 由于未为 `foo-v1` 或 `foo-v2` 指定 `weight`，因此它们会隐式接收与其各自路由规则匹配的 100% 流量。

金丝雀路由规则（匹配标头 `traffic=test`）用于在将生产用户流量拆分到 `foo-v2` 之前发送合成测试流量。

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

#### 蓝绿流量滚动更新

在内部测试验证了来自 `foo-v2` 的成功响应后，通常希望将一小部分流量切换到新 Service，以便进行逐步且更真实的测试。以下 HTTPRoute 将 `foo-v2` 作为带有权重的后端添加。

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

#### 完成滚动更新

最后，如果所有信号都正常，就到了将流量完全切换到 `foo-v2` 并完成滚动更新的时候了。通过将 `foo-v1` 的权重设置为 `0`，配置其不再接收流量。

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

此时，100% 的流量都路由到了 `foo-v2`，滚动更新完成。如果由于某种原因 `foo-v2` 出现错误，可以通过更新权重快速将流量切回 `foo-v1`。

---

### 2.5 HTTP 查询参数匹配

HTTPRoute 资源可用于根据查询参数匹配请求。

以下 HTTPRoute 根据 `animal` 查询参数的值在两个后端之间拆分流量：

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

- 带有查询参数 `animal=whale` 的对 `/` 的请求将路由到 `infra-backend-v1`。
- 带有查询参数 `animal=dolphin` 的对 `/` 的请求将路由到 `infra-backend-v2`。

#### 匹配多个查询参数

规则也可以匹配多个查询参数：

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

如果同时存在查询参数 `animal=dolphin` AND `color=blue`，流量将路由到 `infra-backend-v3`。

---

### 2.6 HTTP 方法匹配

HTTPRoute 资源可用于根据 HTTP 方法匹配请求。

以下 HTTPRoute 根据请求的 HTTP 方法在两个后端之间拆分流量：

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

- 对 `/` 的 POST 请求将路由到 `infra-backend-v1`。
- 对 `/` 的 GET 请求将路由到 `infra-backend-v2`。

#### 与其他匹配类型组合

方法匹配可以与路径和标头匹配等其他匹配类型结合使用：

```yaml
rules:
# 与核心匹配类型组合
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

## 3. 高级功能

### 3.1 跨命名空间（Cross-Namespace）路由

Gateway API 为跨命名空间路由提供了核心支持。这在多个用户或团队共享基础网络架构，但需要分离控制和配置以最小化访问和故障域时非常有用。

#### 场景

在本指南中，有两个独立的团队 `store` 和 `site`，它们在同一个 Kubernetes 集群的 `store-ns` 和 `site-ns` 命名空间中运营。

**目标：**
- **site 团队**：有两个应用 `home` 和 `login`。该团队希望尽可能隔离应用间的访问和配置，以最小化访问和故障域。
- **store 团队**：在 `store-ns` 命名空间部署了一个名为 `store` 的单个 Service，该 Service 也需要暴露在同一个 IP 地址和域名下。
- **基础架构团队**：在 `infra-ns` 命名空间运营并控制 `foo.example.com` 域名。
- **安全团队**：控制 `foo.example.com` 的证书。

#### 部署共享 Gateway

基础架构团队在 `infra-ns` 命名空间部署 `shared-gateway` Gateway：

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

该 Gateway 的 `https` 监听器匹配发往 `foo.example.com` 域名的流量。它还使用 `infra-ns` 命名空间中的 `foo-example-com` Secret 配置 HTTPS。

此 Gateway 使用命名空间选择器定义哪些 HTTPRoute 可以连接：

```yaml
allowedRoutes:
  namespaces:
    from: Selector
    selector:
      matchLabels:
        shared-gateway-access: "true"
```

只有标记有 `shared-gateway-access: "true"` 标签的命名空间才能将 Route 连接到 `shared-gateway`。

#### 部署 HTTPRoute

**store 团队的 HTTPRoute：**

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

该 Route 具有简单的路由逻辑，匹配 `/store` 流量并将其发送到 `store` Service。

**site 团队的 HTTPRoute：**

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

### 3.2 TLS 设置

Gateway API 允许以各种方式配置 TLS。

#### TLS 连接类型

Gateway API 区分两种主要的 TLS 连接：

1. **downstream**：客户端与 Gateway 之间的连接
2. **upstream**：Gateway 与路由中指定的后端资源之间的连接

#### 基础 TLS 配置

在以下示例中，Gateway 为所有请求提供 `default-cert` Secret 资源中定义的 TLS 证书：

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

#### 按主机名配置 TLS

在此示例中，Gateway 被配置为服务 `foo.example.com` 和 `bar.example.com` 域名：

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

#### 通配符 TLS 配置

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

#### 跨命名空间证书引用

在此示例中，Gateway 被配置为引用其他命名空间中的证书。这是通过在目标命名空间中创建的 ReferenceGrant 允许的：

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

### 3.3 TCP 路由

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

---

### 3.4 gRPC 路由

使用 GRPCRoute 资源，您可以匹配 gRPC 流量并将其转发到 Kubernetes 后端。本指南展示了 GRPCRoute 如何在主机、标头、服务和方法字段中匹配流量，并将其转发到不同的 Kubernetes Service。

#### 流量流

下图说明了跨三个不同 Service 的所需流量流：

- 对 `com.Example.Login` 方法发往 `foo.f5bnk.com` 的流量转发到 `foo-svc`
- 带有 `env: canary` 标头发往 `bar.f5bnk.com` 的流量对于所有服务和方法都转发到 `bar-svc-canary`
- 不带标头发往 `bar.f5bnk.com` 的流量对于所有服务和方法都转发到 `bar-svc`

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

#### 主机名与方法匹配

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

---

## 总结

本文涵盖了 Gateway API 的主要用户指南：

1. **开始使用**：简单的 Gateway 部署和 Ingress 迁移
2. **HTTP 路由**：基础路由、重定向/重写、标头修改、流量拆分、查询参数及方法匹配
3. **高级功能**：跨命名空间路由、TLS 设置、TCP 及 gRPC 路由

每个功能都结合实际用例提供了详细的 YAML 示例，展示了 Gateway API 强大且灵活的功能。

欲了解更多信息，请参考 [Gateway API 官方文档](https://gateway-api.sigs.k8s.io/)。
