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
