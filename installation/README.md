# F5 BIG-IP Next for Kubernetes(BNK) 安装指南

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
