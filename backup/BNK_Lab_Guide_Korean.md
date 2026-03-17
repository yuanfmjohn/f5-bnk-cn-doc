# F5 BIG-IP Next for Kubernetes (BNK) 实验指南
## 全模块详细指南 (中文)

> **原文出处**: F5 BIG-IP Next Training Lab  
> **版本**: Latest  
> **翻译与整理**: 2024年 12月

---

## 📚 目录

### [模块 1: 实验环境介绍](#模块-1-实验环境介绍)
- [Kubernetes 集群部署](#1-1-kubernetes-集群部署)
- [Kubernetes 网络模型](#1-2-kubernetes-网络模型)
- [网络插件部署](#1-3-网络插件部署)
- [在虚拟机上创建实验网络](#1-4-在虚拟机上创建实验网络)
- [BIG-IP Next 网络选项](#1-5-big-ip-next-网络选项)
- [创建路由器和客户端容器](#1-6-路由器及客户端容器创建)

### [模块 2: 安装 BIG-IP Next for Kubernetes](#模块-2-安装-big-ip-next-for-kubernetes)
- [安装社区服务及资源](#2-1-社区服务及资源安装)
- [添加 F5 实用工具集群租户](#2-2-f5-实用工具集群租户添加)
- [启用 FAR 访问](#2-3-far-访问启用)
- [启用 BIG-IP Next 调试服务访问](#2-4-big-ip-next-调试服务访问启用)
- [安装 BIG-IP Next for Kubernetes 部署](#2-5-big-ip-next-for-kubernetes-部署安装)
- [NVIDIA DPU 节点上的 BIG-IP Next](#2-6-nvidia-dpu-节点上的-big-ip-next)
- [创建用于 Ingress 和 Egress 的 Kubernetes 租户网络](#2-7-创建用于-ingress-及-egress-的-kubernetes-租户网络)

### [模块 3: 使用 BIG-IP Next for Kubernetes](#模块-3-使用-big-ip-next-for-kubernetes)
- [创建 Red 租户 Deployment 和 Service](#3-1-red-租户-deployment-及-service-创建)
- [创建 Ingress GatewayType, Gateway, TCPRoute](#3-2-ingress-gatewaytype-gateway-tcproute-创建)
- [测试 BIG-IP Next for Kubernetes Ingress](#3-3-big-ip-next-for-kubernetes-ingress-测试)
- [在 Red 租户容器中确认 Egress](#3-4-在-red-租户容器中确认-egress)
- [通过 Grafana 探索 BIG-IP Next 遥测数据](#3-5-通过-grafana-探索-big-ip-next-遥测数据)

---

# 模块 1: 实验环境介绍

## 概览

在本实验中，我们将利用 UDF (Unified Demo Framework) 设置 Kubernetes 环境。

BIG-IP Next for Kubernetes 是模块化的，可以根据不同规模进行部署。在本实验开发环境中，我们利用 KinD (Kubernetes in Docker) 在单个虚拟机上构建 Kubernetes 集群。

### 最终实验网络拓扑图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Virtual Machine                          │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Kubernetes Cluster (KinD)                     │  │
│  │                                                             │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │  │
│  │  │ bnk-worker   │  │ bnk-worker2  │  │ bnk-worker3  │    │  │
│  │  │              │  │              │  │              │    │  │
│  │  │  BIG-IP TMM  │  │  BIG-IP TMM  │  │  BIG-IP TMM  │    │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │  │
│  │                                                             │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │         bnk-control-plane                            │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────┐                      ┌──────────────┐         │
│  │ infra-frr-1  │ ◄─── BGP Peering ─── │              │         │
│  │  (Router)    │                      │              │         │
│  └──────────────┘                      └──────────────┘         │
│                                                                   │
│  ┌──────────────┐                                                │
│  │infra-client-1│                                                │
│  │  (Client)    │                                                │
│  └──────────────┘                                                │
│                                                                   │
│  Networks:                                                        │
│  • kind (bridge)           - Kubernetes 节点连接                │
│  • external-net (macvlan)  - Ingress Virtual Servers             │
│  • egress-net (macvlan)    - Egress SNAT                         │
│  • infra_client-net        - Client 网络                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1-1. Kubernetes 集群部署

### 初始环境确认

登录实验 Web 控制台 UI 后，切换到 **ubuntu** 用户。

```bash
# 切换到 ubuntu 用户
su -l ubuntu

# 确认 Docker 网络
docker network ls
```

**输出示例:**
```
NETWORK ID     NAME      DRIVER    SCOPE
938d048cb58f   bridge    bridge    local
a7e18706eb7a   host      host      local
3ac8b0046fd9   none      null      local
```

目前仅存在 Docker 默认网络:
- **bridge**: 隔离的宿主机网络
- **host**: 直接连接到宿主机的现有网络接口
- **none**: 无网络

### KinD (Kubernetes in Docker) 介绍

**什么是 KinD?**
- Kubernetes in Docker 的缩写
- 使用 Docker 容器作为“节点”来运行本地 Kubernetes 集群的工具
- 对开发、测试、CI 环境特别有用

**更多信息:**
- [KinD 官方网站](https://kind.sigs.k8s.io/)
- [Kubectl 官方文档](https://kubernetes.io/docs/reference/kubectl/)
- [Helm 官方网站](https://helm.sh/)

### 创建 Kubernetes 集群

```bash
# 确认当前正在运行的容器 (正常情况下应为空)
docker ps

# 创建 Kubernetes 集群
./create-cluster.sh
```

**脚本操作:**
1. 下载 KinD 节点容器镜像
2. 运行 4 个容器并配置 Kubernetes 集群

**确认生成的容器:**

```bash
# 确认容器列表
docker ps

# 确认 Kubernetes 节点
kubectl get nodes
```

**输出示例:**
```
NAME                STATUS     ROLES           AGE     VERSION
bnk-control-plane   NotReady   control-plane   9m46s   v1.32.0
bnk-worker          NotReady   <none>          9m35s   v1.32.0
bnk-worker2         NotReady   <none>          9m35s   v1.32.0
bnk-worker3         NotReady   <none>          9m35s   v1.32.0
```

**节点处于 NotReady 状态的原因:**
因为尚未安装 CNI (Container Network Interface) 插件。

---

## 1-2. Kubernetes 网络模型

### Kubernetes 网络概念

Kubernetes 网络旨在让容器能够高度敏捷地部署在 'Pod' 内。

**核心原则:**
- 每个 Pod 都有唯一的 IP 地址
- 同一集群的所有 Pod 都可以直接相互通信
- Service 分配静态 IP 并通过 Endpoint 进行负载均衡

### Kubernetes Service 类型

1. **ClusterIP**
   - 在整个集群内可访问的服务 IP 和端口
   - [官方文档](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip)

2. **NodePort**
   - 可通过 Kubernetes 节点 IP 地址和端口从数据中心访问
   - [官方文档](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

3. **LoadBalancer**
   - 可从外部访问的 L4 负载均衡服务
   - 将流量转发到内部集群服务
   - [官方文档](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

4. **Ingress**
   - 可从外部访问的 L7 基于 HTTP 的负载均衡
   - [官方文档](https://kubernetes.io/docs/concepts/services-networking/ingress/)

5. **Gateway** (NEW!)
   - CNCF 标准服务
   - NetOps 基础设施管理员定义监听器 (Listener)
   - DevOps 应用管理员定义路由 (Route)
   - 支持路由:
     - L4: **TCPRoute**, **UDPRoute**
     - L6: **TLSRoute**
     - L7: **HTTPRoute** (HTTP/1.0, HTTP/2.0, gRPC)
   - 可通过自定义路由进行扩展
   - [官方文档](https://kubernetes.io/docs/concepts/services-networking/gateway/)

---

## 1-3. 网络插件部署

### CNI (Container Network Interface) 插件

**什么是 CNI?**
- 负责在 Pod 中创建网络接口并分配 IP 地址
- 当 Kubernetes 调度 Pod 时，CNI 会创建网络连接

[CNI 官方网站](https://www.cni.dev/)

### 安装 Calico CNI

**什么是 Calico?**
- 广泛使用的网络插件
- 在容器调度时提供网络接口和 IP 地址
- [Calico 官方文档](https://docs.tigera.io/calico/latest/about)

**基本操作:**
- Pod 默认拥有一个网络接口 (**eth0**) 和一个 Pod 网络 IP 地址

### 安装 Multus CNI

**什么是 Multus?**
- 控制在 Kubernetes Pod 中创建额外的网络接口
- 通过 **NetworkAttachmentDefinition** 资源进行抽象
- 像 BIG-IP 代理这类用于流量处理的额外接口需要它

[Multus 官方 GitHub](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/README.md)

### 部署 CNI 和 Multus

```bash
# 部署 CNI 和 Multus
./deploy-cni.sh
```

**输出示例:**
```
Create CNI and Multus ...
poddisruptionbudget.policy/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
serviceaccount/calico-node created
configmap/calico-config created
...
clusterrole.rbac.authorization.k8s.io/multus created
clusterrolebinding.rbac.authorization.k8s.io/multus created
serviceaccount/multus created
configmap/multus-cni-config created
daemonset.apps/kube-multus-ds created
configmap/cni-install-sh created
daemonset.apps/install-cni-plugins created

Waiting for Kubernetes control plane to get ready ...
```

### 再次确认节点状态

```bash
kubectl get nodes
```

**输出示例:**
```
NAME                STATUS   ROLES           AGE   VERSION
bnk-control-plane   Ready    control-plane   54m   v1.32.0
bnk-worker          Ready    <none>          54m   v1.32.0
bnk-worker2         Ready    <none>          54m   v1.32.0
bnk-worker3         Ready    <none>          54m   v1.32.0
```

现在所有节点都处于 **Ready** 状态了！

### 确认 Pod 列表

```bash
kubectl get pods -A
```

**核心 Pod:**
- **calico-kube-controllers**: 集群用 Calico 控制器 (1个)
- **calico-node**: 每个节点的 Calico 代理 (DaemonSet)
- **kube-multus-ds**: 每个节点的 Multus (DaemonSet)

### 再次确认 Docker 网络

```bash
docker network ls
```

**输出示例:**
```
NETWORK ID     NAME      DRIVER    SCOPE
938d048cb58f   bridge    bridge    local
a7e18706eb7a   host      host      local
01c75852c676   kind      bridge    local  ← KinD 添加的网络
3ac8b0046fd9   none      null      local
```

---

## 1-4. 在虚拟机上创建实验网络

### 所需网络

目前 Docker 中只有 KinD 集群使用的 **kind** 网络。此外还需要创建以下网络:
- **infra_client-net**: 客户端网络
- **external-net**: 用于 BIG-IP Ingress Virtual Server 的 MACVLAN
- **egress-net**: 用于 BIG-IP Egress SNAT 的 MACVLAN

### 创建实验网络

```bash
./create-lab-networks.sh
```

**输出示例:**
```
Creating docker networks external-net and egress-net and attach both to worker nodes ...
9fbe21d0d55bddd34a04dc41aa5261961e4780046729c515609b0d7d5fb4c28e
65fd7b73f6042d14a4e900c94f45df836c9ecff311fe88685f6c5e5c3d6dffd3
node/bnk-worker annotated
node/bnk-worker2 annotated
node/bnk-worker3 annotated
Flush IP on eth1 in each worker node, the node won't use it, only TMM will
```

**生成的网络:**
- **infra_client-net** (bridge): 客户端用
- **external-net** (macvlan): Ingress Virtual Server 用
- **egress-net** (macvlan): Egress SNAT 用

### 确认网络列表

```bash
docker network ls
```

**输出示例:**
```
NETWORK ID     NAME               DRIVER    SCOPE
a749e9e46e78   bridge             bridge    local
65fd7b73f604   egress-net         macvlan   local
9fbe21d0d55b   external-net       macvlan   local
a7e18706eb7a   host               host      local
4f6963ba7d7d   infra_client-net   bridge    local
c23770001ba1   kind               bridge    local
3ac8b0046fd9   none               null      local
```

### 创建 Multus NetworkAttachmentDefinition

Multus **NetworkAttachmentDefinition** 定义了 BIG-IP Pod 如何连接到额外的网络接口。

**外部网络定义 (resources/networks.yaml):**

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: external-net
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {}
    }'
```

**Egress 网络定义:**

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: egress-net
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth2",
      "mode": "bridge",
      "ipam": {}
    }'
```

### 创建 Network Attachment

```bash
./create-bigip-network-attachements.sh
```

**输出示例:**
```
Create Multus Network Attachments ...
networkattachmentdefinition.k8s.cni.cncf.io/external-net created
networkattachmentdefinition.k8s.cni.cncf.io/egress-net created

NAME           AGE
egress-net     0s
external-net   0s
```

**网络接口映射:**
- Calico 创建 **eth0** (标准 Pod 网络)
- Multus 创建 **eth1** (external-net)
- Multus 创建 **eth2** (egress-net)

---

## 1-5. BIG-IP Next 网络选项

BIG-IP Next for Kubernetes 可以通过多种方式进行连接。

### 选项 1: 在 DPU 上实现完全的宿主机卸载 (Offload)

**使用 NVIDIA BlueField-3 DPU:**
- DPU 是独立的 SoC (System on a Chip) 处理器
- 拥有自己的网络连接选项
- 使用 NVIDIA DOCA 网络加速 API
- F5 与 NVIDIA BlueField-3 的集成通过 DOCA 'scalable functions' 直接连接到 DPU 的硬件 eSwitch
- 每个 DPU 上的 BIG-IP 处理宿主机的所有工作负载流量

**架构:**
```
┌────────────────────────────────────┐
│         Host Node                   │
│  ┌──────────────────────────────┐  │
│  │   Application Workloads       │  │
│  │   (Kubernetes Pods)           │  │
│  └──────────────┬────────────────┘  │
│                 │                    │
│  ┌──────────────▼────────────────┐  │
│  │  NVIDIA BlueField-3 DPU       │  │
│  │  ┌────────────────────────┐   │  │
│  │  │  BIG-IP Next (TMM)     │   │  │
│  │  │  - DOCA API            │   │  │
│  │  │  - Hardware eSwitch    │   │  │
│  │  └────────────────────────┘   │  │
│  └───────────────────────────────┘  │
│                 │                    │
│                 ▼                    │
│         Physical Network             │
└────────────────────────────────────┘
```

[完整安装指南](https://f5devcentral.github.io/f5-bnk-nvidia-bf3-installations/)

### 选项 2: 使用 DPDK 在宿主机系统运行

**DPDK (Data Plane Development Kit):**
- 用于用户态进程 (执行单元) 的加速网络访问标准
- 预分配网络设备、计算核心和内存
- 通过对专用网络接口队列的数据轮询进行访问
- 将宿主机内核从中断处理程序中卸载
- 提高网络处理速度并降低延迟

**BIG-IP Next 数据平面:**
- 从 DPDK 网络接口驱动到 HTTP 等完整应用协议的完整代理堆栈

**架构:**
```
┌────────────────────────────────────┐
│         Host System                 │
│  ┌──────────────────────────────┐  │
│  │   Application Pods            │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  BIG-IP Next (DPDK Mode)     │  │
│  │  - Dedicated CPU Cores       │  │
│  │  - Pre-allocated Memory      │  │
│  │  - Dedicated NICs            │  │
│  └──────────────┬───────────────┘  │
│                 │                   │
│                 ▼                   │
│      Physical Network Interfaces    │
└────────────────────────────────────┘
```

### 选项 3: 通过宿主机 Linux 内核网络连接

**Linux 网络:**
- 各种虚拟网络设备和套接字 API 层
- BIG-IP Next 可以使用 'raw sockets'
- 与宿主机完全共享网络接口
- 与专用网络接口和计算资源相比，性能较低且延迟较高

**用于测试环境的 MACVLAN:**
- 类似于虚拟机的虚拟网络接口方式
- **本实验中使用的方式**
- 可以在 Multus **NetworkAttachmentDefinition** 中确认

**架构:**
```
┌────────────────────────────────────┐
│         Host System                 │
│  ┌──────────────────────────────┐  │
│  │   Application Pods            │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  BIG-IP Next (Linux Netdev)  │  │
│  │  - Raw Sockets               │  │
│  │  - MACVLAN Interfaces        │  │
│  │  - Shared NICs               │  │
│  └──────────────┬───────────────┘  │
│                 │                   │
│  ┌──────────────▼───────────────┐  │
│  │  Linux Kernel Network Stack  │  │
│  └──────────────┬───────────────┘  │
│                 │                   │
│                 ▼                   │
│      Physical Network Interfaces    │
└────────────────────────────────────┘
```

---

## 1-6. 创建路由器和客户端容器

### 部署 Free Range Routing (FRR) 路由器

**什么是 FRR?**
- 开源路由守护程序集合
- 使用容器化版本
- 部署为 **infra-frr-1** 容器
- 连接到 **external-net** 和 **infra_client-net**

[FRRouting 官方文档](https://docs.frrouting.org/)

### 部署客户端容器

**infra-client-1:**
- 简单的 nginx 演示容器
- 用于观察客户端和 Egress 流量

### 使用 Docker Compose 进行容器编排

```bash
./create-router-and-client-containers.sh
```

**输出示例:**
```
Deploy FRR and client docker container ...
[+] Running 4/4
 ✔ Network infra_client-net  Created  0.2s
 ✔ Container infra-frr-1     Started  0.5s
 ✔ Container infra-client-1  Started  0.5s
 ✔ Container syslog-server   Started  0.5s
```

### 最终实验环境

现在实验环境已完成:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Virtual Machine                          │
│                                                                   │
│  ┌───────────────── Kubernetes Cluster (KinD) ────────────────┐ │
│  │  Control Plane + Worker Nodes (with Calico & Multus)      │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ infra-frr-1  │────│ external-net │────│  BIG-IP Next │      │
│  │  (Router)    │    │ (MACVLAN)    │    │   (TMM)      │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│        │                                                          │
│        │                                                          │
│  ┌──────────────┐                                                │
│  │infra-client-1│                                                │
│  │  (Client)    │                                                │
│  └──────────────┘                                                │
│                                                                   │
│  Networks:                                                        │
│  • kind               • external-net   • egress-net              │
│  • infra_client-net                                              │
└─────────────────────────────────────────────────────────────────┘
```

标准 Kubernetes 环境的所有组件已就绪。现在可以开始部署 BIG-IP Next for Kubernetes 了！

---

# 模块 2: 安装 BIG-IP Next for Kubernetes

## 概览

在本模块中，我们将安装在实验运行环境中运行 BIG-IP Next for Kubernetes 所需的所有组件。

### 重要通知

**基于 OLM (Operator Lifecycle Manager) 的安装:**

本实验出于教学目的提供分步安装过程。在 BIG-IP Next for Kubernetes GA (General Availability) 版本中，安装将通过符合 OLM 的 Operator 进行配置。

**保持冷静，继续实验！**

[详细了解 OLM Operators](https://olm.operatorframework.io/)

---

## 2-1. 安装社区服务及资源

### 安装 Cert-Manager

**什么是 Cert-Manager?**
- 用于服务间零信任通信的证书颁发工具
- 包含在许多 Kubernetes 发行版中的开源组件
- Pod 间通信安全及定期 Secret 轮转自动化

[详细了解 Cert-Manager](https://cert-manager.io/)

**安装命令:**

```bash
./create-cert-manager.sh
```

**输出示例:**
```
Install cert-manager and cluster issuer to manage pod-to-pod certs ...
"jetstack" has been added to your repositories
Release "cert-manager" does not exist. Installing it now.
NAME: cert-manager
LAST DEPLOYED: Thu Feb 20 07:28:10 2025
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.16.1 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/

pod/cert-manager-74b7f6cbbc-fblj8 condition met
pod/cert-manager-cainjector-58c9d76cb8-4qcdk condition met
pod/cert-manager-webhook-5875b545cf-bp5cn condition met
clusterissuer.cert-manager.io/selfsigned-cluster-issuer created
certificate.cert-manager.io/bnk-ca created
clusterissuer.cert-manager.io/bnk-ca-cluster-issuer created
```

### 安装 Gateway API CRD

**什么是 Gateway API?**
- CNCF (Cloud Native Computing Foundation) 标准 API
- 定义了 BIG-IP Next for Kubernetes 使用的资源

[详细了解 Gateway API](https://gateway-api.sigs.k8s.io/)

### 安装 Prometheus 和 Grafana

**Prometheus:**
- 指标收集工具
- [详细了解 Prometheus](https://prometheus.io/)

**Grafana:**
- 遥测仪表板可视化工具
- [详细了解 Grafana](https://github.com/grafana/grafana/blob/main/README.md)

### 生成 OTEL (OpenTelemetry) 证书

**OpenTelemetry:**
- 用于 BIG-IP Next OTEL 服务安全通信的证书
- [详细了解 OTEL](https://opentelemetry.io/)

### 部署所有组件

```bash
./deploy-gatewayapi-telemetry.sh
```

**输出示例:**
```
Install Gateway API CRDs ...
customresourcedefinition.apiextensions.k8s.io/backendlbpolicies.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/tcproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/udproutes.gateway.networking.k8s.io created

Install Prometheus and Grafana ...
certificate.cert-manager.io/prometheus created
deployment.apps/prometheus created
configmap/prometheus-config created
service/prometheus-service created
clusterrole.rbac.authorization.k8s.io/prometheus-default created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-default created
deployment.apps/grafana created
configmap/grafana-datasources created
service/grafana created

Install OTEL prerequired cert ...
certificate.cert-manager.io/external-otelsvr created
certificate.cert-manager.io/external-f5ingotelsvr created
```

---

## 2-2. 添加 F5 实用工具集群租户

将 BIG-IP Next for Kubernetes 的所有共享实用组件放置在适当的命名空间中。这使我们能够妥善保护集群中对这些资源的访问。

```bash
./create-f5util-namespace.sh
```

**输出示例:**
```
Create f5-utils namespace for BNK supporting software
namespace/f5-utils created
```

---

## 2-3. 启用 FAR 访问

### F5 Artifact Registry (FAR) 介绍

云原生应用从各种软件仓库下载:
- **Docker Hub**: Docker 推出的最熟悉的仓库
- **Red Hat Quay**: Kubernetes 发行版厂商仓库
- **超大规模云提供商仓库**

**私有仓库:**
- 基于 mTLS 的身份验证和授权控制软件资源访问

**F5 Artifact Registry (FAR):**
- 提供容器镜像、编排文件、清单文件、实用工具文件
- 需要基于证书的凭据

### 如何获取 FAR 凭据

**官方流程:**
1. 需要登录 [My F5](https://my.f5.com)
2. [FAR 凭据下载指南](https://clouddocs.f5.com/bigip-next-for-kubernetes/2.0.0-LA/far.html#download-the-service-account-key)

**实验环境:**
- 由于不能确定所有用户都有 my.f5.com 访问权限
- FAR 身份验证凭据已预先复制到实验虚拟机

### 确认 FAR 凭据

```bash
ls far/f5-far-auth-key.tgz
```

**输出:**
```
far/f5-far-auth-key.tgz
```

### Helm 介绍

**Helm:**
- Kubernetes 原生包管理器
- [详细了解 Helm](https://helm.sh/)

### 添加 FAR 仓库

```bash
./add-far-registry.sh
```

**输出示例:**
```
F5 Artifacts Registry (FAR) authentication token ...
Create the secret.yaml file with the provided content ...
secret/far-secret created
secret/far-secret created
Login Succeeded
```

**操作:**
1. 将凭据添加为 Kubernetes Secret
2. 将 FAR 添加为 Helm 仓库
3. 测试登录

---

## 2-4. 启用 BIG-IP Next 调试服务访问

我们需要创建一种方法，使集群外部的客户端能够安全地与集群内部的调试服务通信。

**需要外部访问的服务:**
- 产品信息收集
- 许可报告
- 用于 Support 的 QKView 收集
- 调试流量访问

**保存凭据:**
- 保存在 Kubernetes Secrets 中
- 为模块 3 的演示，也复制到虚拟机宿主机的文件中

### 安装 CWC (Cluster Wide Controller)

```bash
./install-cwc.sh
```

**输出示例:**
```
Install Cluster Wide Controller (CWC) to manage license and debug API ...
Pulled: repo.f5.com/utils/f5-cert-gen:0.9.1
Digest: sha256:89d283a7b2fef651a29baf1172c590d45fbd1e522fa90207ecd73d440708ad34
~/cwc ~
------------------------------------------------------------------
Service                   = api-server
Subject Alternate Name    = f5-spk-cwc.f5-utils
Working directory         = /home/ubuntu/cwc/api-server-secrets
------------------------------------------------------------------
...
Creating 1 client extensions...
...
Copying secrets ...
Generating /home/ubuntu/cwc/cwc-license-certs.yaml
Generating /home/ubuntu/cwc/cwc-license-client-certs.yaml
~
secret/cwc-license-certs created
Create directory for API client certs for easier reference ...
~/cwc ~
~

Install cwc-reqs ...
configmap/cpcl-key-cm created
configmap/cwc-qkview-cm created
```

最后的预备环境资源已完成。现在可以安装 BIG-IP 了！

---

## 2-5. 安装 BIG-IP Next for Kubernetes 部署

使用 Helm 安装符合 OLM 的 Operator。该 Operator 会动态编排 BIG-IP Next for Kubernetes 组件的生命周期。

**Operator 的优点:**
- 在 Kubernetes 集群中持续运行的编排器
- 自动执行任务

### 安装 BIG-IP Next for Kubernetes

```bash
./install-bnk.sh
```

**输出示例:**
```
Install BNK ...
configmap/bnk-bgp created
node/bnk-worker2 labeled
node/bnk-worker3 labeled
...

Install orchestrator ...
Release "orchestrator" does not exist. Installing it now.
NAME: orchestrator
LAST DEPLOYED: Thu Feb 20 14:31:25 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
..../create
```

**Orchestrator 操作:**
- 持续运行并监控资源添加或更改
- 在 BIG-IP 需要编排时自动处理

### 确认 Orchestrator Pod

```bash
kubectl get pod | grep orchestrator
```

**输出示例:**
```
orchestrator-f5cbc78cf-kfgxx        1/1     Running   0          1m
```

**安装完成！**
- 节点打标签
- 安装 Orchestrator
- 砰！安装完成

---

## 2-6. NVIDIA DPU 节点上的 BIG-IP Next

### 模拟 DPU 模式

在本次安装中，我们标记了两个节点并将其专门分配给 BIG-IP Next。虽然不必非要这样做，但这模拟了 NVIDIA DPU 的呈现方式。

### NVIDIA BlueField-3 DPU 模式

**启用 DPU 时:**
- 在集群中显示为独立节点
- 以相同方式对节点打标签
- Operator 以相同方式执行安装

**架构:**

```
┌────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Host Node 1  │  │ Host Node 2  │  │ Host Node 3  │     │
│  │              │  │              │  │              │     │
│  │ Application  │  │ Application  │  │ Application  │     │
│  │   Workloads  │  │   Workloads  │  │   Workloads  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐        │
│  │ BF-3 DPU 1  │  │ BF-3 DPU 2  │  │ BF-3 DPU 3  │        │
│  │ (Node)      │  │ (Node)      │  │ (Node)      │        │
│  │             │  │             │  │             │        │
│  │  BIG-IP TMM │  │  BIG-IP TMM │  │  BIG-IP TMM │        │
│  │  DOCA API   │  │  DOCA API   │  │  DOCA API   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

**Kubernetes 节点视图:**
```
NAME                     STATUS   ROLES           AGE   VERSION
bnk-control-plane        Ready    control-plane   1h    v1.32.0
bnk-host-1               Ready    <none>          1h    v1.32.0
bnk-host-2               Ready    <none>          1h    v1.32.0
bnk-host-3               Ready    <none>          1h    v1.32.0
bnk-bf3-dpu-1            Ready    <none>          1h    v1.32.0  ← DPU 节点
bnk-bf3-dpu-2            Ready    <none>          1h    v1.32.0  ← DPU 节点
bnk-bf3-dpu-3            Ready    <none>          1h    v1.32.0  ← DPU 节点
```

---

## 2-7. 创建用于 Ingress 和 Egress 的 Kubernetes 租户网络

为 Blue 和 Red 租户创建网络。

```bash
./create-tenants.sh
```

**输出示例:**
```
Create red tenant namespace...
Error from server (AlreadyExists): namespaces "red" already exists

Create blue tenant namespace...
Error from server (AlreadyExists): namespaces "blue" already exists

Creating VLANs for tenant ingress
f5spkvlan.k8s.f5net.com/external created
f5spkvlan.k8s.f5net.com/egress created
f5spkvlan.k8s.f5net.com/egress condition met
f5spkvlan.k8s.f5net.com/external condition met

Install vxlan for tenant egress
f5spkvxlan.k8s.f5net.com/red created
f5spkvxlan.k8s.f5net.com/blue created
f5spkvxlan.k8s.f5net.com/blue condition met
f5spkvxlan.k8s.f5net.com/red condition met

Install SNAT Pools to be selected on egress for tenant namespaces
f5spksnatpool.k8s.f5net.com/red-snat created
f5spksnatpool.k8s.f5net.com/blue-snat created
f5spkegress.k8s.f5net.com/red-egress created
f5spkegress.k8s.f5net.com/blue-egress created

Little lab hack to disable TX offload capabilities on egress vxlans

bnk-worker2
bnk-worker
Actual changes:
tx-checksum-ip-generic: off
tx-tcp-segmentation: off [not requested]
tx-tcp-ecn-segmentation: off [not requested]
tx-tcp-mangleid-segmentation: off [not requested]
tx-tcp6-segmentation: off [not requested]
Actual changes:
tx-checksum-ip-generic: off
tx-tcp-segmentation: off [not requested]
tx-tcp-ecn-segmentation: off [not requested]
tx-tcp-mangleid-segmentation: off [not requested]
tx-tcp6-segmentation: off [not requested]

bnk-worker3

Install a global logging profile for all tenants
f5bigcontextglobal.k8s.f5net.com/global-context configured
f5bigloghslpub.k8s.f5net.com/logpublisher created
f5biglogprofile.k8s.f5net.com/logprofile created
```

### 生成的资源

**命名空间:**
- `red`: Red 租户
- `blue`: Blue 租户

**网络资源:**
- **F5SPKVlan**: 用于 Ingress 的 VLAN (external, egress)
- **F5SPKVxlan**: 用于 Egress 的 VXLAN (red, blue)
- **F5SPKSnatpool**: Egress SNAT 池 (red-snat, blue-snat)
- **F5SPKEgress**: Egress 配置 (red-egress, blue-egress)

**日志:**
- **F5BigContextGlobal**: 全局上下文
- **F5BigLogHslpub**: 日志发布器
- **F5BigLogProfile**: 日志配置文件

### 租户网络架构

```
┌─────────────────────────────────────────────────────────────┐
│                  BIG-IP Next for Kubernetes                  │
│                                                               │
│  ┌───────────────── Ingress Networks ──────────────────┐    │
│  │                                                       │    │
│  │  External VLAN ───┬─── Red Virtual Servers          │    │
│  │                   └─── Blue Virtual Servers         │    │
│  │                                                       │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌───────────────── Egress Networks ───────────────────┐    │
│  │                                                       │    │
│  │  Red VXLAN + SNAT Pool (192.0.2.100-101)            │    │
│  │  Blue VXLAN + SNAT Pool (192.0.2.110-111)           │    │
│  │                                                       │    │
│  └───────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

BIG-IP Next for Kubernetes 和两个基础设施租户网络已成功安装！

现在，在模块 3 中，我们将实际使用 BIG-IP Next for Kubernetes。

---

# 模块 3: 使用 BIG-IP Next for Kubernetes

## 概览

在本模块中，我们将部署多租户服务中使用的 Gateway。

BIG-IP Next for Kubernetes 的核心目的是控制对 Kubernetes 应用服务的交付。让我们在 Red 租户中创建一些服务。

---

## 3-1. 创建 Red 租户 Deployment 和 Service

### 部署 Nginx 演示 Pod

**部署资源:**
- Kubernetes **Deployment**: Nginx TCP 演示 Pod
- Kubernetes **Service**: 为 Deployment 提供稳定的 IP 地址

```bash
kubectl apply -f resources/nginx-red-deployment.yaml
```

**输出示例:**
```
deployment.apps/nginx-deployment created
service/nginx-app-svc created
```

**资源结构:**

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: red
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: nginx-app-svc
  namespace: red
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

---

## 3-2. 创建 Ingress GatewayType, Gateway, TCPRoute

### 创建 Gateway API 资源

现在是有趣的部分！我们将扮演 NetOps 角色，创建 Gateway API **GatewayClass** 和 **Gateway** 资源。

### 角色分离

**NetOps 用户:**
- 创建 **GatewayClass**: 决定使用哪个 BIG-IP Next for Kubernetes 实例
- 创建 **Gateway**: 决定数据中心地址和监听器端口

**DevOps 用户:**
- 创建 **L4Route** (或 HTTPRoute): 选择要使用的 Gateway

### 定义 GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: f5-gateway-class
  namespace: red
spec:
  controllerName: "f5.com/f5-gateway-controller"
  description: "F5 BIG-IP Kubernetes Gateway"
```

**说明:**
- 指定 Gateway 使用的控制器
- 与 F5 BIG-IP Next for Kubernetes 实例连接

### 定义 Gateway

```yaml
apiVersion: gateway.k8s.f5net.com/v1
kind: Gateway
metadata:
  name: my-l4route-tcp-gateway
  namespace: red
spec:
  addresses:
  - type: "IPAddress"
    value: 198.19.19.100        # Red 租户 VIP
  gatewayClassName: f5-gateway-class
  listeners:
  - name: nginx
    protocol: TCP
    port: 80
    allowedRoutes:
      kinds:
      - kind: L4Route
```

**说明:**
- **addresses**: 供外部访问的 VIP (Virtual IP)
- **listeners**: 定义协议和端口
- **allowedRoutes**: 指定允许的路由种类

### 定义 L4Route

```yaml
apiVersion: gateway.k8s.f5net.com/v1
kind: L4Route
metadata:
  name: l4-tcp-app
  namespace: red
spec:
  protocol: TCP
  parentRefs:
  - name: my-l4route-tcp-gateway
    sectionName: nginx
  rules:
  - backendRefs:
    - name: nginx-app-svc
      namespace: red
      port: 80
```

**说明:**
- **parentRefs**: 指定要使用的 Gateway
- **backendRefs**: 指定实际的后端服务

### 部署 Gateway 资源

```bash
kubectl apply -f resources/nginx-red-gw-api.yaml
```

**输出示例:**
```
gatewayclass.gateway.networking.k8s.io/f5-gateway-class created
gateway.gateway.k8s.f5net.com/my-l4route-tcp-gateway created
l4route.gateway.k8s.f5net.com/l4-tcp-app created
```

---

## 3-3. 测试 BIG-IP Next for Kubernetes Ingress

### 理解架构

```
┌──────────────┐                                  ┌─────────────┐
│infra-client-1│                                  │  Red Pod    │
│   (Client)   │                                  │   (nginx)   │
│              │                                  │             │
│198.51.100.100│                                  │10.244.x.x:80│
└──────┬───────┘                                  └──────▲──────┘
       │                                                  │
       │ HTTP Request                                    │
       │ to 198.19.19.100                               │
       │                                                  │
       ▼                                                  │
┌──────────────┐        BGP Peering         ┌───────────┴──────┐
│ infra-frr-1  │◄──────────────────────────►│  BIG-IP Next     │
│   (Router)   │                             │     (TMM)        │
│              │                             │                  │
│              │   ECMP Routes               │  VIP:            │
│              │   198.19.19.100/32          │  198.19.19.100   │
│              │   → 192.0.2.201             │                  │
│              │   → 192.0.2.202             │  Pool Members:   │
│              │                             │  10.244.x.x:80   │
└──────────────┘                             └──────────────────┘
```

### Ingress 测试

```bash
docker exec -ti infra-client-1 curl -I http://198.19.19.100
```

**输出示例:**
```
HTTP/1.1 200 OK
Server: nginx/1.27.4
Date: Thu, 20 Feb 2025 18:04:34 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 05 Feb 2025 11:06:32 GMT
Connection: keep-alive
ETag: "67a34638-267"
Accept-Ranges: bytes
```

成功！客户端已通过 BIG-IP Next 访问 Red 租户的 Nginx 服务。

### 确认 BGP Peering

**路由器是如何找到 BIG-IP 的？** 通过 BGP (Border Gateway Protocol) 对等互联。

```bash
docker exec -ti infra-frr-1 vtysh -c "show bgp summary"
```

**输出示例:**
```
IPv4 Unicast Summary (VRF default):
BGP router identifier 192.0.2.250, local AS number 65500 vrf-id 0
BGP table version 7
RIB entries 11, using 2112 bytes of memory
Peers 3, using 2151 KiB of memory
Peer groups 1, using 64 bytes of memory

Neighbor           V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
*192.0.2.201       4      64443       376       379        0    0    0 03:06:11            3        6 N/A
*192.0.2.202       4      64443       376       379        0    0    0 03:06:18            3        6 N/A
*2001::192:0:2:202 4      64443        13        14        0    0    0 00:05:06        NoNeg    NoNeg N/A

Total number of neighbors 3
* - dynamic neighbor
3 dynamic neighbor(s), limit 100
```

**确认事项:**
- 两个 BIG-IP Next 实例 (192.0.2.201, 192.0.2.202) 与路由器建立了对等互联

### 确认路由表

```bash
docker exec -ti infra-frr-1 vtysh -c "show ip route"
```

**输出示例:**
```
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

K>* 0.0.0.0/0 [0/0] via 198.51.100.1, eth0, 03:26:14
C>* 192.0.2.0/24 is directly connected, eth1, 03:26:14
B>* 192.0.2.100/32 [20/0] via 192.0.2.201, eth1, weight 1, 03:08:51
B>* 192.0.2.101/32 [20/0] via 192.0.2.202, eth1, weight 1, 03:09:04
B>* 192.0.2.110/32 [20/0] via 192.0.2.201, eth1, weight 1, 03:08:51
B>* 192.0.2.111/32 [20/0] via 192.0.2.202, eth1, weight 1, 03:09:04
B>* 198.19.19.100/32 [20/0] via 192.0.2.201, eth1, weight 1, 00:14:18  ← Red VIP
  *                         via 192.0.2.202, eth1, weight 1, 00:14:18  ← ECMP
C>* 198.51.100.0/24 is directly connected, eth0, 03:26:14
```

**核心点:**
- Red 服务的 VIP **198.19.19.100/32** 通过 BGP 进行通告
- 通过 ECMP (Equal-Cost Multi-Path) 在两个 BIG-IP Next 实例间均等分配流量

### 课堂讨论: 基于 ECMP 的 Ingress 路由

**Virtual Server 地址:**
- 由 NetOps 用户设置的 VIP 可被与路由器建立对等互联的所有 BIG-IP Next 实例访问

**接下来会发生什么？**

**选项 1: 通过 ClusterIP 进行代理 (不使用)**
- BIG-IP Next 使用 ClusterIP 地址配置 Pool Member
- 转发到一个，kube-proxy 将其代理到 Endpoint Pod IP
- 浪费 CPU 资源 (使用 kube-proxy 和 netfilter/iptables NAT 规则)

**选项 2: 直接使用 Endpoint Pod IP (BIG-IP Next 方式)**
- 发现与 Service 关联的 Endpoint Pod IP
- 使用 Pod IP 地址配置 Pool
- 发现每个 Pod 部署的节点
- 将负载均衡后的请求路由到正确的节点 IP，目的地为 Pod IP

### 确认 Service 和 Endpoint

**Red Service:**

```bash
kubectl get service -n red
```

**输出:**
```
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
nginx-app-svc   ClusterIP   10.96.157.55   <none>        80/TCP    4m
```

**Endpoints:**

```bash
kubectl get endpoints -n red
```

**输出:**
```
NAME            ENDPOINTS           AGE
nginx-app-svc   10.244.227.201:80   5m
```

**BIG-IP Next 的优化:**
- 不使用 ClusterIP，直接路由到 Pod IP
- **消除 kube-proxy 开销**
- 节省大量 CPU 周期！

---

## 3-4. 在 Red 租户容器中确认 Egress

### Egress 架构

```
┌──────────────┐                                  ┌─────────────┐
│  Red Pod     │                                  │infra-client-1│
│   (nginx)    │                                  │  Web Server │
│              │                                  │             │
│10.244.x.x    │                                  │198.51.100.100│
└──────┬───────┘                                  └──────▲──────┘
       │                                                  │
       │ Outbound HTTP                                   │
       │ Request                                          │
       │                                                  │
       ▼                                                  │
┌──────────────┐                             ┌───────────┴──────┐
│  BIG-IP Next │                             │  infra-frr-1     │
│     (TMM)    │────────────────────────────►│    (Router)      │
│              │                             │                  │
│  SNAT Pool:  │   Source IP:                │                  │
│  192.0.2.100 │   192.0.2.100 or            │                  │
│  192.0.2.101 │   192.0.2.101               │                  │
└──────────────┘                             └──────────────────┘
```

### 确认 Red SNAT Pool

```bash
kubectl describe f5-spk-snatpool red-snat
```

**输出示例:**
```
Name:         red-snat
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  k8s.f5net.com/v1
Kind:         F5SPKSnatpool
Metadata:
  Creation Timestamp:  2025-02-20T15:05:18Z
  Finalizers:
    handletmmconfig_inconsistency
  Generation:        1
  Resource Version:  6173
  UID:               923fe787-13bc-44c0-bf19-678ca38ab198
Spec:
  Address List:
    [192.0.2.100 2001::192:0:2:100]
    [192.0.2.101 2001::192:0:2:101]
  Name:                         red-snat
  Shared Snat Address Enabled:  false
Status:
  Conditions:
    Last Transition Time:  2025-02-20T15:05:18Z
    Message:
    Observed Generation:   0
    Reason:                Accepted
    Status:                True
    Type:                  Accepted
    Last Transition Time:  2025-02-20T15:05:18Z
    Message:               CR config sent to all grpc endpoints
    Observed Generation:   2
    Reason:                Programmed
    Status:                True
    Type:                  Programmed
  Generation Id:           0
Events:                    <none>
```

**SNAT Pool 地址:**
- 192.0.2.100 (IPv4) / 2001::192:0:2:100 (IPv6)
- 192.0.2.101 (IPv4) / 2001::192:0:2:101 (IPv6)

### 测试 Egress 流量

从 Red Pod 生成外部 Web 请求，并确认 infra-client-1 Web 服务看到的源 IP。

```bash
kubectl exec -ti -n red deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**输出示例:**
```
================================================
 ___ ___   ___                    _
| __| __| |   \ ___ _ __  ___    /_\  _ __ _ __
| _||__ \ | |) / -_) '  \/ _ \  / _ \| '_ \ '_ \
|_| |___/ |___/\___|_|_|_\___/ /_/ \_\ .__/ .__/
                                      |_|  |_|
================================================

      Node Name: F5 Docker vLab
     Short Name: nginx

      Server IP: 198.51.100.100
    Server Port: 80

      Client IP: 192.0.2.100          ← Red SNAT Pool 地址！
    Client Port: 62899

Client Protocol: HTTP
 Request Method: GET
    Request URI: /txt

    host_header: 198.51.100.100
     user-agent: curl/7.88.1
```

**成功！**
- Red 租户命名空间的 Pod 发起 Egress 请求
- 流量已适当地应用了 SNAT
- 源 IP: **192.0.2.100** (Red SNAT Pool)

### 部署 Blue 租户

一次性完成 Blue 租户的完整部署。

```bash
kubectl apply -f ./resources/nginx-blue-deployment.yaml
```

**输出示例:**
```
deployment.apps/nginx-deployment created
service/nginx-app-svc created
gateway.gateway.k8s.f5net.com/my-l4route-tcp-gateway created
l4route.gateway.k8s.f5net.com/l4-tcp-app created
```

### 确认 Blue SNAT Pool

```bash
kubectl describe f5-spk-snatpool blue-snat
```

**核心部分:**
```
Spec:
  Address List:
    [192.0.2.110 2001::192:0:2:110]
    [192.0.2.111 2001::192:0:2:111]
  Name:                         blue-snat
```

### 测试 Blue Egress

```bash
kubectl exec -ti -n blue deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**输出示例:**
```
================================================
      Server IP: 198.51.100.100
    Server Port: 80

      Client IP: 192.0.2.111          ← Blue SNAT Pool 地址！
    Client Port: 10764

Client Protocol: HTTP
 Request Method: GET
    Request URI: /txt
```

**成功！**
- Blue 租户: **192.0.2.110** 或 **192.0.2.111**
- Red 租户: **192.0.2.100** 或 **192.0.2.101**

### 网络分段 (Segmentation) 的重要性

**日志、可观测性、防火墙规则:**
- 通过确认 Egress 流量的源 IP，可以识别 Red 和 Blue 租户
- 仅通过检查源 IP 即可区分 Kubernetes 租户

**在 AI/ML 环境中的重要性:**
- 共享 GPU 的租户的流量安全
- 使用 RAG (Retrieval Augmented Generation) 时
- 从特定策略文档库中获取数据时
- 必须通过网络分段确保安全性！

---

## 3-5. 通过 Grafana 探索 BIG-IP Next 遥测数据

### 访问 Grafana

在浏览器中打开实验提供的 Grafana URL。

**默认凭据:**
- 用户名: **admin**
- 密码: **admin**

**登录后:**
- 会要求修改密码 (可进行修改或跳过)

### 加载 F5 BNK Dashboard

**路径:**
1. 导航到 Dashboard 菜单
2. 加载 F5 BNK Dashboard

**仪表板配置:**
- **TMM (Data Path)** 可视化
- **ACL** 可视化
- **Red 租户** 独立可视化
- **Blue 租户** 独立可视化

### 生成并观察流量

**生成 Ingress 流量:**

```bash
# Red 租户 Ingress
docker exec -ti infra-client-1 curl http://198.19.19.100/txt

# Blue 租户 Ingress
docker exec -ti infra-client-1 curl http://198.20.20.100/txt
```

**生成 Egress 流量:**

```bash
# Red 租户 Egress
kubectl exec -ti -n red deploy/nginx-deployment -- curl http://198.51.100.100/txt

# Blue 租户 Egress
kubectl exec -ti -n blue deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**观察 Grafana 仪表板:**
- 实时流量可视化
- 按 Red 和 Blue 租户划分的统计数据
- TMM 性能指标
- ACL 规则应用现状

---

## 实验演示摘要

本实验演示了以下内容:

### 1. Kubernetes 集群概念及细节

**网络:**
- CNI 插件 (Calico, Multus)
- Service 类型 (ClusterIP, NodePort, LoadBalancer)
- Gateway API

**资源:**
- Deployment, Service, Endpoints
- 自定义资源定义 (CRDs)
- Gateway, GatewayClass, L4Route/HTTPRoute

### 2. BIG-IP Next for Kubernetes 安装及运作方式

**安装组件:**
- Cert-Manager (证书管理)
- Gateway API CRDs
- Prometheus & Grafana (监控)
- F5 Artifact Registry (FAR) 访问
- Cluster Wide Controller (CWC)
- Orchestrator

**网络配置:**
- VLAN (用于 Ingress)
- VXLAN (用于 Egress)
- SNAT 池
- BGP 路由

### 3. 多租户应用交付及安全

**Ingress:**
- 通过 Gateway API 暴露 VIP
- 基于 ECMP 的负载均衡
- 直接 Pod IP 路由 (绕过 kube-proxy)
- 通过 BGP 进行路径通告

**Egress:**
- 按租户划分的 SNAT 池
- 通过 VXLAN 实现网络分段
- 基于源 IP 的流量识别

**监控:**
- Prometheus 指标收集
- Grafana 可视化
- 按租户划分的遥测数据

---

## 更多学习资源

**官方文档:**
- [BIG-IP Next for Kubernetes 官方文档](https://clouddocs.f5.com/bigip-next-for-kubernetes/latest/)
- [Gateway API 官方网站](https://gateway-api.sigs.k8s.io/)
- [Kubernetes 网络](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

**F5 资源:**
- [F5 DevCentral](https://community.f5.com/)
- [F5 Support](https://support.f5.com/)
- [NVIDIA BlueField-3 集成指南](https://f5devcentral.github.io/f5-bnk-nvidia-bf3-installations/)

**相关技术:**
- [Calico CNI](https://docs.tigera.io/calico/latest/about)
- [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)
- [KinD (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [Helm 包管理器](https://helm.sh/)
- [FRRouting](https://docs.frrouting.org/)

---

## 结论

通过本实验，您学习了:

1. **Kubernetes 基础**
   - 集群构成及网络
   - CNI 插件运作方式
   - Service 及 Gateway API

2. **BIG-IP Next for Kubernetes 安装**
   - 完整安装流程
   - 必需组件配置
   - 多租户网络配置

3. **实际使用**
   - 通过 Gateway API 暴露应用
   - Ingress 及 Egress 流量管理
   - 遥测及监控

**主要优点:**
- **性能优化**: 绕过 kube-proxy，直接 Pod IP 路由
- **网络分段**: 按租户划分 SNAT 池
- **扩展性**: 基于 ECMP 的负载均衡
- **可观测性**: 集成 Prometheus/Grafana
- **符合标准**: Gateway API, OLM Operator

---

**文档编写日期**: 2024年 12月  
**翻译者**: Claude (AI Assistant)  
**原文出处**: F5 BIG-IP Next Training Lab  
**版本**: Latest
