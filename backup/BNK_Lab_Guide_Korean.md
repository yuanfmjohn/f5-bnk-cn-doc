# F5 BIG-IP Next for Kubernetes (BNK) 랩 가이드
## 전체 모듈 상세 가이드 (한국어)

> **원문 출처**: F5 BIG-IP Next Training Lab  
> **버전**: Latest  
> **번역 및 정리**: 2024년 12월

---

## 📚 목차

### [모듈 1: 랩 환경 소개](#모듈-1-랩-환경-소개)
- [Kubernetes 클러스터 배포](#1-1-kubernetes-클러스터-배포)
- [Kubernetes 네트워킹 모델](#1-2-kubernetes-네트워킹-모델)
- [네트워크 플러그인 배포](#1-3-네트워크-플러그인-배포)
- [가상 머신에 랩 네트워크 생성](#1-4-가상-머신에-랩-네트워크-생성)
- [BIG-IP Next 네트워크 옵션](#1-5-big-ip-next-네트워크-옵션)
- [라우터 및 클라이언트 컨테이너 생성](#1-6-라우터-및-클라이언트-컨테이너-생성)

### [모듈 2: BIG-IP Next for Kubernetes 설치](#모듈-2-big-ip-next-for-kubernetes-설치)
- [커뮤니티 서비스 및 리소스 설치](#2-1-커뮤니티-서비스-및-리소스-설치)
- [F5 유틸리티 클러스터 테넌트 추가](#2-2-f5-유틸리티-클러스터-테넌트-추가)
- [FAR 접근 활성화](#2-3-far-접근-활성화)
- [BIG-IP Next 디버그 서비스 접근 활성화](#2-4-big-ip-next-디버그-서비스-접근-활성화)
- [BIG-IP Next for Kubernetes 배포 설치](#2-5-big-ip-next-for-kubernetes-배포-설치)
- [NVIDIA DPU 노드의 BIG-IP Next](#2-6-nvidia-dpu-노드의-big-ip-next)
- [Ingress 및 Egress용 Kubernetes 테넌트 네트워크 생성](#2-7-ingress-및-egress용-kubernetes-테넌트-네트워크-생성)

### [모듈 3: BIG-IP Next for Kubernetes 사용](#모듈-3-big-ip-next-for-kubernetes-사용)
- [Red 테넌트 Deployment 및 Service 생성](#3-1-red-테넌트-deployment-및-service-생성)
- [Ingress GatewayType, Gateway, TCPRoute 생성](#3-2-ingress-gatewaytype-gateway-tcproute-생성)
- [BIG-IP Next for Kubernetes Ingress 테스트](#3-3-big-ip-next-for-kubernetes-ingress-테스트)
- [Red 테넌트 컨테이너에서 Egress 확인](#3-4-red-테넌트-컨테이너에서-egress-확인)
- [Grafana를 통한 BIG-IP Next 텔레메트리 탐색](#3-5-grafana를-통한-big-ip-next-텔레메트리-탐색)

---

# 모듈 1: 랩 환경 소개

## 개요

본 랩에서는 UDF (Unified Demo Framework)를 활용하여 Kubernetes 환경을 설정합니다.

BIG-IP Next for Kubernetes는 모듈식으로 다양한 규모로 배포할 수 있습니다. 본 랩 개발 환경에서는 KinD (Kubernetes in Docker)를 활용하여 단일 가상 머신에 Kubernetes 클러스터를 구축합니다.

### 최종 랩 네트워크 다이어그램

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
│  • kind (bridge)           - Kubernetes 노드 연결                │
│  • external-net (macvlan)  - Ingress Virtual Servers             │
│  • egress-net (macvlan)    - Egress SNAT                         │
│  • infra_client-net        - Client 네트워크                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1-1. Kubernetes 클러스터 배포

### 초기 환경 확인

랩 웹 콘솔 UI에 로그인한 후, **ubuntu** 사용자로 전환합니다.

```bash
# ubuntu 사용자로 전환
su -l ubuntu

# Docker 네트워크 확인
docker network ls
```

**출력 예시:**
```
NETWORK ID     NAME      DRIVER    SCOPE
938d048cb58f   bridge    bridge    local
a7e18706eb7a   host      host      local
3ac8b0046fd9   none      null      local
```

현재는 Docker 기본 네트워크만 존재합니다:
- **bridge**: 분리된 호스트 네트워크
- **host**: 호스트의 기존 네트워크 인터페이스에 직접 연결
- **none**: 네트워킹 없음

### KinD (Kubernetes in Docker) 소개

**KinD란?**
- Kubernetes in Docker의 약자
- Docker 컨테이너를 "노드"로 사용하여 로컬 Kubernetes 클러스터를 실행하는 도구
- 개발, 테스트, CI 환경에 특히 유용

**추가 정보:**
- [KinD 공식 사이트](https://kind.sigs.k8s.io/)
- [Kubectl 공식 문서](https://kubernetes.io/docs/reference/kubectl/)
- [Helm 공식 사이트](https://helm.sh/)

### Kubernetes 클러스터 생성

```bash
# 현재 실행 중인 컨테이너 확인 (없어야 정상)
docker ps

# Kubernetes 클러스터 생성
./create-cluster.sh
```

**스크립트 동작:**
1. KinD 노드 컨테이너 이미지 다운로드
2. 4개의 컨테이너 실행 및 Kubernetes 클러스터 구성

**생성된 컨테이너 확인:**

```bash
# 컨테이너 목록 확인
docker ps

# Kubernetes 노드 확인
kubectl get nodes
```

**출력 예시:**
```
NAME                STATUS     ROLES           AGE     VERSION
bnk-control-plane   NotReady   control-plane   9m46s   v1.32.0
bnk-worker          NotReady   <none>          9m35s   v1.32.0
bnk-worker2         NotReady   <none>          9m35s   v1.32.0
bnk-worker3         NotReady   <none>          9m35s   v1.32.0
```

**노드가 NotReady 상태인 이유:**
아직 CNI (Container Network Interface) 플러그인이 설치되지 않았기 때문입니다.

---

## 1-2. Kubernetes 네트워킹 모델

### Kubernetes 네트워킹 개념

Kubernetes 네트워킹은 컨테이너를 'Pod' 내에 고도로 민첩하게 배포할 수 있도록 설계되었습니다.

**핵심 원칙:**
- 각 Pod는 고유한 IP 주소를 가짐
- 동일 클러스터의 모든 Pod는 서로 직접 통신 가능
- Service는 정적 IP를 할당하고 Endpoint로 로드밸런싱

### Kubernetes Service 타입

1. **ClusterIP**
   - 클러스터 전체에서 접근 가능한 서비스 IP 및 포트
   - [공식 문서](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip)

2. **NodePort**
   - Kubernetes 노드 IP 주소와 포트로 데이터 센터에서 접근 가능
   - [공식 문서](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

3. **LoadBalancer**
   - 외부에서 접근 가능한 L4 로드밸런싱 서비스
   - 내부 클러스터 서비스로 트래픽 전달
   - [공식 문서](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

4. **Ingress**
   - 외부에서 접근 가능한 L7 HTTP 기반 로드밸런싱
   - [공식 문서](https://kubernetes.io/docs/concepts/services-networking/ingress/)

5. **Gateway** (NEW!)
   - CNCF 표준 서비스
   - NetOps 인프라 관리자가 리스너 정의
   - DevOps 애플리케이션 관리자가 라우트 정의
   - 지원 라우트:
     - L4: **TCPRoute**, **UDPRoute**
     - L6: **TLSRoute**
     - L7: **HTTPRoute** (HTTP/1.0, HTTP/2.0, gRPC)
   - 커스텀 라우트로 확장 가능
   - [공식 문서](https://kubernetes.io/docs/concepts/services-networking/gateway/)

---

## 1-3. 네트워크 플러그인 배포

### CNI (Container Network Interface) 플러그인

**CNI란?**
- Pod에 네트워크 인터페이스 생성 및 IP 주소 할당을 담당
- Kubernetes가 Pod를 스케줄링하면 CNI가 네트워크 연결 생성

[CNI 공식 사이트](https://www.cni.dev/)

### Calico CNI 설치

**Calico란?**
- 널리 사용되는 네트워크 플러그인
- 컨테이너 스케줄링 시 네트워크 인터페이스 및 IP 주소 제공
- [Calico 공식 문서](https://docs.tigera.io/calico/latest/about)

**기본 동작:**
- Pod는 기본적으로 하나의 네트워크 인터페이스(**eth0**)와 하나의 Pod 네트워크 IP 주소를 가짐

### Multus CNI 설치

**Multus란?**
- Kubernetes Pod에 추가 네트워크 인터페이스 생성을 제어
- **NetworkAttachmentDefinition** 리소스를 통해 추상화
- BIG-IP 프록시와 같은 트래픽 처리용 추가 인터페이스에 필요

[Multus 공식 GitHub](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/README.md)

### CNI 및 Multus 배포

```bash
# CNI 및 Multus 배포
./deploy-cni.sh
```

**출력 예시:**
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

### 노드 상태 재확인

```bash
kubectl get nodes
```

**출력 예시:**
```
NAME                STATUS   ROLES           AGE   VERSION
bnk-control-plane   Ready    control-plane   54m   v1.32.0
bnk-worker          Ready    <none>          54m   v1.32.0
bnk-worker2         Ready    <none>          54m   v1.32.0
bnk-worker3         Ready    <none>          54m   v1.32.0
```

이제 모든 노드가 **Ready** 상태입니다!

### Pod 목록 확인

```bash
kubectl get pods -A
```

**주요 Pod:**
- **calico-kube-controllers**: 클러스터용 Calico 컨트롤러 (1개)
- **calico-node**: 각 노드의 Calico 에이전트 (DaemonSet)
- **kube-multus-ds**: 각 노드의 Multus (DaemonSet)

### Docker 네트워크 재확인

```bash
docker network ls
```

**출력 예시:**
```
NETWORK ID     NAME      DRIVER    SCOPE
938d048cb58f   bridge    bridge    local
a7e18706eb7a   host      host      local
01c75852c676   kind      bridge    local  ← KinD가 추가한 네트워크
3ac8b0046fd9   none      null      local
```

---

## 1-4. 가상 머신에 랩 네트워크 생성

### 필요한 네트워크

현재 Docker에는 KinD 클러스터용 **kind** 네트워크만 있습니다. 추가로 다음 네트워크를 생성해야 합니다:
- **infra_client-net**: 클라이언트 네트워크
- **external-net**: BIG-IP Ingress Virtual Server용 MACVLAN
- **egress-net**: BIG-IP Egress SNAT용 MACVLAN

### 랩 네트워크 생성

```bash
./create-lab-networks.sh
```

**출력 예시:**
```
Creating docker networks external-net and egress-net and attach both to worker nodes ...
9fbe21d0d55bddd34a04dc41aa5261961e4780046729c515609b0d7d5fb4c28e
65fd7b73f6042d14a4e900c94f45df836c9ecff311fe88685f6c5e5c3d6dffd3
node/bnk-worker annotated
node/bnk-worker2 annotated
node/bnk-worker3 annotated
Flush IP on eth1 in each worker node, the node won't use it, only TMM will
```

**생성된 네트워크:**
- **infra_client-net** (bridge): 클라이언트용
- **external-net** (macvlan): Ingress Virtual Server용
- **egress-net** (macvlan): Egress SNAT용

### 네트워크 목록 확인

```bash
docker network ls
```

**출력 예시:**
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

### Multus NetworkAttachmentDefinition 생성

Multus **NetworkAttachmentDefinition**은 BIG-IP Pod가 추가 네트워크 인터페이스에 연결하는 방법을 정의합니다.

**외부 네트워크 정의 (resources/networks.yaml):**

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

**Egress 네트워크 정의:**

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

### Network Attachment 생성

```bash
./create-bigip-network-attachements.sh
```

**출력 예시:**
```
Create Multus Network Attachments ...
networkattachmentdefinition.k8s.cni.cncf.io/external-net created
networkattachmentdefinition.k8s.cni.cncf.io/egress-net created

NAME           AGE
egress-net     0s
external-net   0s
```

**네트워크 인터페이스 매핑:**
- Calico가 **eth0** 생성 (표준 Pod 네트워크)
- Multus가 **eth1** 생성 (external-net)
- Multus가 **eth2** 생성 (egress-net)

---

## 1-5. BIG-IP Next 네트워크 옵션

BIG-IP Next for Kubernetes는 여러 방식으로 연결할 수 있습니다.

### 옵션 1: DPU에서 완전한 호스트 오프로드

**NVIDIA BlueField-3 DPU 사용:**
- DPU는 독립적인 SoC (System on a Chip) 프로세서
- 자체 네트워크 연결 옵션 보유
- NVIDIA DOCA 네트워크 가속 API 사용
- F5의 NVIDIA BlueField-3 통합은 DOCA 'scalable functions'를 통해 DPU의 하드웨어 eSwitch에 직접 연결
- 각 DPU의 BIG-IP가 호스트의 모든 워크로드 트래픽 처리

**아키텍처:**
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

[전체 설치 가이드](https://f5devcentral.github.io/f5-bnk-nvidia-bf3-installations/)

### 옵션 2: DPDK로 호스트 시스템에서 실행

**DPDK (Data Plane Development Kit):**
- 사용자 프로세스(실행 단위)용 가속 네트워크 액세스 표준
- 네트워크 장치, 컴퓨팅 코어 및 메모리를 사전 할당
- 전용 네트워크 인터페이스 큐의 데이터 폴링으로 액세스
- 호스트 커널을 인터럽트 핸들러에서 오프로드
- 네트워크 처리 속도 향상 및 지연 시간 감소

**BIG-IP Next 데이터 플레인:**
- DPDK 네트워크 인터페이스 드라이버부터 HTTP 같은 전체 애플리케이션 프로토콜까지 완전한 프록시 스택

**아키텍처:**
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

### 옵션 3: 호스트 Linux 커널 네트워킹을 통한 연결

**Linux 네트워킹:**
- 다양한 가상 네트워크 디바이스 및 소켓 API 레이어
- BIG-IP Next는 'raw sockets' 사용 가능
- 네트워크 인터페이스를 호스트와 완전히 공유
- 전용 네트워크 인터페이스 및 컴퓨팅 리소스와 비교 시 성능 및 지연 시간 저하

**테스트 환경용 MACVLAN:**
- 가상 머신과 유사한 방식의 가상 네트워킹 인터페이스
- **본 랩에서 사용하는 방식**
- Multus **NetworkAttachmentDefinition**에서 확인 가능

**아키텍처:**
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

## 1-6. 라우터 및 클라이언트 컨테이너 생성

### Free Range Routing (FRR) 라우터 배포

**FRR이란?**
- 오픈 소스 라우팅 데몬 모음
- 컨테이너화된 버전 사용
- **infra-frr-1** 컨테이너로 배포
- **external-net** 및 **infra_client-net**에 연결

[FRRouting 공식 문서](https://docs.frrouting.org/)

### 클라이언트 컨테이너 배포

**infra-client-1:**
- 간단한 nginx 데모 컨테이너
- 클라이언트 및 Egress 트래픽 관찰용

### Docker Compose를 사용한 컨테이너 오케스트레이션

```bash
./create-router-and-client-containers.sh
```

**출력 예시:**
```
Deploy FRR and client docker container ...
[+] Running 4/4
 ✔ Network infra_client-net  Created  0.2s
 ✔ Container infra-frr-1     Started  0.5s
 ✔ Container infra-client-1  Started  0.5s
 ✔ Container syslog-server   Started  0.5s
```

### 최종 랩 환경

이제 랩 환경이 완성되었습니다:

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

표준 Kubernetes 환경의 모든 구성 요소가 준비되었습니다. 이제 BIG-IP Next for Kubernetes를 배포할 준비가 완료되었습니다!

---

# 모듈 2: BIG-IP Next for Kubernetes 설치

## 개요

본 모듈에서는 랩 환경에서 BIG-IP Next for Kubernetes를 실행하는 데 필요한 모든 구성 요소를 설치합니다.

### 중요 공지

**OLM (Operator Lifecycle Manager) 기반 설치:**

본 랩은 교육 목적으로 단계별 설치 과정을 안내합니다. BIG-IP Next for Kubernetes GA (General Availability) 버전에서는 OLM 준수 Operator를 통해 설치가 구성됩니다.

**STAY CALM and Lab On!**

[OLM Operators 자세히 보기](https://olm.operatorframework.io/)

---

## 2-1. 커뮤니티 서비스 및 리소스 설치

### Cert-Manager 설치

**Cert-Manager란?**
- 서비스 간 제로 트러스트 통신을 위한 인증서 발급 도구
- 많은 Kubernetes 배포판에 포함된 오픈 소스 컴포넌트
- Pod 간 통신 보안 및 정기적인 시크릿 로테이션 자동화

[Cert-Manager 자세히 보기](https://cert-manager.io/)

**설치 명령:**

```bash
./create-cert-manager.sh
```

**출력 예시:**
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

### Gateway API CRD 설치

**Gateway API란?**
- CNCF (Cloud Native Computing Foundation) 표준 API
- BIG-IP Next for Kubernetes가 사용하는 리소스 정의

[Gateway API 자세히 보기](https://gateway-api.sigs.k8s.io/)

### Prometheus 및 Grafana 설치

**Prometheus:**
- 메트릭 수집 도구
- [Prometheus 자세히 보기](https://prometheus.io/)

**Grafana:**
- 텔레메트리 대시보드 시각화 도구
- [Grafana 자세히 보기](https://github.com/grafana/grafana/blob/main/README.md)

### OTEL (OpenTelemetry) 인증서 생성

**OpenTelemetry:**
- BIG-IP Next OTEL 서비스가 안전하게 통신하기 위한 인증서
- [OTEL 자세히 보기](https://opentelemetry.io/)

### 전체 컴포넌트 배포

```bash
./deploy-gatewayapi-telemetry.sh
```

**출력 예시:**
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

## 2-2. F5 유틸리티 클러스터 테넌트 추가

BIG-IP Next for Kubernetes의 모든 공유 유틸리티 컴포넌트를 적절한 네임스페이스에 배치합니다. 이를 통해 클러스터에서 이러한 리소스에 대한 접근을 적절히 보호할 수 있습니다.

```bash
./create-f5util-namespace.sh
```

**출력 예시:**
```
Create f5-utils namespace for BNK supporting software
namespace/f5-utils created
```

---

## 2-3. FAR 접근 활성화

### F5 Artifact Registry (FAR) 소개

클라우드 네이티브 앱은 다양한 소프트웨어 레지스트리에서 다운로드됩니다:
- **Docker Hub**: Docker가 소개한 가장 친숙한 레지스트리
- **Red Hat Quay**: Kubernetes 배포판 벤더 레지스트리
- **하이퍼스케일 클라우드 제공업체 레지스트리**

**프라이빗 레지스트리:**
- mTLS 기반 인증 및 권한 부여로 소프트웨어 리소스 접근 제어

**F5 Artifact Registry (FAR):**
- 컨테이너 이미지, 오케스트레이션 파일, 매니페스트 파일, 유틸리티 파일 제공
- 인증서 기반 자격 증명 필요

### FAR 자격 증명 획득 방법

**공식 프로세스:**
1. [My F5](https://my.f5.com) 로그인 필요
2. [FAR 자격 증명 다운로드 가이드](https://clouddocs.f5.com/bigip-next-for-kubernetes/2.0.0-LA/far.html#download-the-service-account-key)

**랩 환경:**
- 모든 사용자가 my.f5.com 접근 권한이 있는지 확신할 수 없으므로
- FAR 인증 자격 증명을 랩 가상 머신에 미리 복사

### FAR 자격 증명 확인

```bash
ls far/f5-far-auth-key.tgz
```

**출력:**
```
far/f5-far-auth-key.tgz
```

### Helm 소개

**Helm:**
- Kubernetes 네이티브 패키지 관리자
- [Helm 자세히 보기](https://helm.sh/)

### FAR 레지스트리 추가

```bash
./add-far-registry.sh
```

**출력 예시:**
```
F5 Artifacts Registry (FAR) authentication token ...
Create the secret.yaml file with the provided content ...
secret/far-secret created
secret/far-secret created
Login Succeeded
```

**동작:**
1. 자격 증명을 Kubernetes Secret으로 추가
2. FAR을 Helm 리포지토리로 추가
3. 로그인 테스트

---

## 2-4. BIG-IP Next 디버그 서비스 접근 활성화

클러스터 외부의 클라이언트가 클러스터 내부의 디버그 서비스와 안전하게 통신할 수 있는 방법을 생성해야 합니다.

**외부 접근이 필요한 서비스:**
- 제품 정보 수집
- 라이센싱 보고
- Support용 QKView 수집
- 디버그 트래픽 접근

**자격 증명 저장:**
- Kubernetes Secrets에 저장
- 랩 3의 데모를 위해 가상 머신 호스트의 파일에도 복사

### CWC (Cluster Wide Controller) 설치

```bash
./install-cwc.sh
```

**출력 예시:**
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

마지막 사전 준비 환경 리소스가 완료되었습니다. 이제 BIG-IP를 설치할 준비가 되었습니다!

---

## 2-5. BIG-IP Next for Kubernetes 배포 설치

Helm을 사용하여 OLM 준수 Operator를 설치합니다. 이 Operator는 BIG-IP Next for Kubernetes 컴포넌트의 라이프사이클을 동적으로 오케스트레이션합니다.

**Operator의 장점:**
- Kubernetes 클러스터에서 지속적으로 실행되는 오케스트레이터
- 자동으로 작업 수행

### BIG-IP Next for Kubernetes 설치

```bash
./install-bnk.sh
```

**출력 예시:**
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

**Orchestrator 동작:**
- 지속적으로 실행되며 리소스 추가 또는 변경 모니터링
- BIG-IP에서 오케스트레이션 필요 시 자동 처리

### Orchestrator Pod 확인

```bash
kubectl get pod | grep orchestrator
```

**출력 예시:**
```
orchestrator-f5cbc78cf-kfgxx        1/1     Running   0          1m
```

**설치 완료!**
- 노드 레이블링
- Orchestrator 설치
- BOOM! 설치 완료

---

## 2-6. NVIDIA DPU 노드의 BIG-IP Next

### DPU 모드 시뮬레이션

본 설치에서는 두 개의 노드를 레이블링하고 BIG-IP Next 전용으로 할당했습니다. 반드시 이렇게 해야 하는 것은 아니지만, NVIDIA DPU의 모습을 시뮬레이션합니다.

### NVIDIA BlueField-3 DPU 모드

**DPU 활성화 시:**
- 클러스터에서 별도의 노드로 표시됨
- 동일한 방식으로 노드 레이블링
- Operator가 동일한 방식으로 설치 수행

**아키텍처:**

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

**Kubernetes 노드 뷰:**
```
NAME                     STATUS   ROLES           AGE   VERSION
bnk-control-plane        Ready    control-plane   1h    v1.32.0
bnk-host-1               Ready    <none>          1h    v1.32.0
bnk-host-2               Ready    <none>          1h    v1.32.0
bnk-host-3               Ready    <none>          1h    v1.32.0
bnk-bf3-dpu-1            Ready    <none>          1h    v1.32.0  ← DPU Node
bnk-bf3-dpu-2            Ready    <none>          1h    v1.32.0  ← DPU Node
bnk-bf3-dpu-3            Ready    <none>          1h    v1.32.0  ← DPU Node
```

---

## 2-7. Ingress 및 Egress용 Kubernetes 테넌트 네트워크 생성

Blue 및 Red 테넌트를 위한 네트워크를 생성합니다.

```bash
./create-tenants.sh
```

**출력 예시:**
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

### 생성된 리소스

**네임스페이스:**
- `red`: Red 테넌트
- `blue`: Blue 테넌트

**네트워크 리소스:**
- **F5SPKVlan**: Ingress용 VLAN (external, egress)
- **F5SPKVxlan**: Egress용 VXLAN (red, blue)
- **F5SPKSnatpool**: Egress SNAT 풀 (red-snat, blue-snat)
- **F5SPKEgress**: Egress 설정 (red-egress, blue-egress)

**로깅:**
- **F5BigContextGlobal**: 전역 컨텍스트
- **F5BigLogHslpub**: 로그 퍼블리셔
- **F5BigLogProfile**: 로그 프로파일

### 테넌트 네트워크 아키텍처

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

BIG-IP Next for Kubernetes와 두 개의 인프라 테넌트 네트워크 설치가 성공적으로 완료되었습니다!

이제 모듈 3에서 BIG-IP Next for Kubernetes를 실제로 사용해보겠습니다.

---

# 모듈 3: BIG-IP Next for Kubernetes 사용

## 개요

본 모듈에서는 멀티 테넌트 서비스에서 사용할 Gateway를 배포합니다.

BIG-IP Next for Kubernetes의 핵심 목적은 Kubernetes 서비스에 대한 애플리케이션 전달을 제어하는 것입니다. Red 테넌트에 서비스를 생성해보겠습니다.

---

## 3-1. Red 테넌트 Deployment 및 Service 생성

### Nginx 데모 Pod 배포

**배포 리소스:**
- Kubernetes **Deployment**: Nginx TCP 데모 Pod
- Kubernetes **Service**: Deployment에 안정적인 IP 주소 제공

```bash
kubectl apply -f resources/nginx-red-deployment.yaml
```

**출력 예시:**
```
deployment.apps/nginx-deployment created
service/nginx-app-svc created
```

**리소스 구조:**

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

## 3-2. Ingress GatewayType, Gateway, TCPRoute 생성

### Gateway API 리소스 생성

이제 재미있는 부분입니다! NetOps 역할을 하여 Gateway API **GatewayClass** 및 **Gateway** 리소스를 생성합니다.

### 역할 분리

**NetOps 사용자:**
- **GatewayClass** 생성: 어떤 BIG-IP Next for Kubernetes 인스턴스를 사용할지 결정
- **Gateway** 생성: 데이터 센터 주소 및 리스너 포트 결정

**DevOps 사용자:**
- **L4Route** (또는 HTTPRoute) 생성: 어떤 Gateway를 사용할지 선택

### GatewayClass 정의

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

**설명:**
- Gateway가 사용할 컨트롤러 지정
- F5 BIG-IP Next for Kubernetes 인스턴스와 연결

### Gateway 정의

```yaml
apiVersion: gateway.k8s.f5net.com/v1
kind: Gateway
metadata:
  name: my-l4route-tcp-gateway
  namespace: red
spec:
  addresses:
  - type: "IPAddress"
    value: 198.19.19.100        # Red 테넌트 VIP
  gatewayClassName: f5-gateway-class
  listeners:
  - name: nginx
    protocol: TCP
    port: 80
    allowedRoutes:
      kinds:
      - kind: L4Route
```

**설명:**
- **addresses**: 외부에서 접근할 VIP (Virtual IP)
- **listeners**: 프로토콜 및 포트 정의
- **allowedRoutes**: 허용된 라우트 종류 지정

### L4Route 정의

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

**설명:**
- **parentRefs**: 사용할 Gateway 지정
- **backendRefs**: 실제 백엔드 서비스 지정

### Gateway 리소스 배포

```bash
kubectl apply -f resources/nginx-red-gw-api.yaml
```

**출력 예시:**
```
gatewayclass.gateway.networking.k8s.io/f5-gateway-class created
gateway.gateway.k8s.f5net.com/my-l4route-tcp-gateway created
l4route.gateway.k8s.f5net.com/l4-tcp-app created
```

---

## 3-3. BIG-IP Next for Kubernetes Ingress 테스트

### 아키텍처 이해

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

### Ingress 테스트

```bash
docker exec -ti infra-client-1 curl -I http://198.19.19.100
```

**출력 예시:**
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

성공! 클라이언트가 BIG-IP Next를 통해 Red 테넌트의 Nginx 서비스에 접근했습니다.

### BGP Peering 확인

**라우터가 어떻게 BIG-IP를 찾았을까?** BGP (Border Gateway Protocol) 피어링을 통해서입니다.

```bash
docker exec -ti infra-frr-1 vtysh -c "show bgp summary"
```

**출력 예시:**
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

**확인 사항:**
- BIG-IP Next 인스턴스 두 개 (192.0.2.201, 192.0.2.202)가 라우터와 피어링됨

### 라우팅 테이블 확인

```bash
docker exec -ti infra-frr-1 vtysh -c "show ip route"
```

**출력 예시:**
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

**주요 포인트:**
- Red 서비스의 VIP **198.19.19.100/32**가 BGP를 통해 광고됨
- ECMP (Equal-Cost Multi-Path)로 두 BIG-IP Next 인스턴스에 균등 분산

### 클래스 토론: ECMP 기반 Ingress 라우팅

**Virtual Server 주소:**
- NetOps 사용자가 설정한 VIP는 라우터와 피어링된 모든 BIG-IP Next 인스턴스에서 도달 가능

**그 다음 무슨 일이 일어날까?**

**옵션 1: ClusterIP를 통한 프록시 (사용 안 함)**
- BIG-IP Next가 ClusterIP 주소로 pool member 구성
- 하나로 포워딩하고 kube-proxy가 Endpoint Pod IP로 프록시
- CPU 리소스 낭비 (kube-proxy 및 netfilter/iptables NAT 규칙 사용)

**옵션 2: 직접 Endpoint Pod IP 사용 (BIG-IP Next 방식)**
- Service와 연결된 Endpoint Pod IP 발견
- Pod IP 주소로 pool 구성
- 각 Pod가 배포된 노드 발견
- 로드밸런싱된 요청을 올바른 노드 IP로 라우팅, 목적지는 Pod IP

### Service 및 Endpoint 확인

**Red Service:**

```bash
kubectl get service -n red
```

**출력:**
```
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
nginx-app-svc   ClusterIP   10.96.157.55   <none>        80/TCP    4m
```

**Endpoints:**

```bash
kubectl get endpoints -n red
```

**출력:**
```
NAME            ENDPOINTS           AGE
nginx-app-svc   10.244.227.201:80   5m
```

**BIG-IP Next의 최적화:**
- ClusterIP를 사용하지 않고 직접 Pod IP로 라우팅
- **kube-proxy 오버헤드 제거**
- 상당한 CPU 사이클 절약!

---

## 3-4. Red 테넌트 컨테이너에서 Egress 확인

### Egress 아키텍처

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

### Red SNAT Pool 확인

```bash
kubectl describe f5-spk-snatpool red-snat
```

**출력 예시:**
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

**SNAT Pool 주소:**
- 192.0.2.100 (IPv4) / 2001::192:0:2:100 (IPv6)
- 192.0.2.101 (IPv4) / 2001::192:0:2:101 (IPv6)

### Egress 트래픽 테스트

Red Pod에서 외부 웹 요청을 생성하고 infra-client-1 웹 서비스가 어떤 소스 IP를 보는지 확인합니다.

```bash
kubectl exec -ti -n red deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**출력 예시:**
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

      Client IP: 192.0.2.100          ← Red SNAT Pool 주소!
    Client Port: 62899

Client Protocol: HTTP
 Request Method: GET
    Request URI: /txt

    host_header: 198.51.100.100
     user-agent: curl/7.88.1
```

**성공!**
- Red 테넌트 네임스페이스의 Pod에서 Egress 요청 발생
- 트래픽에 SNAT가 적절히 적용됨
- 소스 IP: **192.0.2.100** (Red SNAT Pool)

### Blue 테넌트 배포

Blue 테넌트의 전체 배포를 한 번에 수행합니다.

```bash
kubectl apply -f ./resources/nginx-blue-deployment.yaml
```

**출력 예시:**
```
deployment.apps/nginx-deployment created
service/nginx-app-svc created
gateway.gateway.k8s.f5net.com/my-l4route-tcp-gateway created
l4route.gateway.k8s.f5net.com/l4-tcp-app created
```

### Blue SNAT Pool 확인

```bash
kubectl describe f5-spk-snatpool blue-snat
```

**주요 부분:**
```
Spec:
  Address List:
    [192.0.2.110 2001::192:0:2:110]
    [192.0.2.111 2001::192:0:2:111]
  Name:                         blue-snat
```

### Blue Egress 테스트

```bash
kubectl exec -ti -n blue deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**출력 예시:**
```
================================================
      Server IP: 198.51.100.100
    Server Port: 80

      Client IP: 192.0.2.111          ← Blue SNAT Pool 주소!
    Client Port: 10764

Client Protocol: HTTP
 Request Method: GET
    Request URI: /txt
```

**성공!**
- Blue 테넌트: **192.0.2.110** 또는 **192.0.2.111**
- Red 테넌트: **192.0.2.100** 또는 **192.0.2.101**

### 네트워크 세그멘테이션의 중요성

**로깅, 관찰성, 방화벽 규칙:**
- Egress 트래픽의 소스 IP를 확인하여 Red 및 Blue 테넌트 식별 가능
- 단순히 소스 IP 체크만으로 Kubernetes 테넌트 구분

**AI/ML 환경에서의 중요성:**
- GPU를 공유하는 테넌트의 트래픽 보안
- RAG (Retrieval Augmented Generation) 사용 시
- 특정 정책 문서 코퍼스에서 데이터 가져올 때
- 네트워크 세그멘테이션으로 보안 보장 필수!

---

## 3-5. Grafana를 통한 BIG-IP Next 텔레메트리 탐색

### Grafana 접속

랩에서 제공된 Grafana URL로 브라우저를 엽니다.

**기본 자격 증명:**
- Username: **admin**
- Password: **admin**

**로그인 후:**
- 비밀번호 변경 요청 (진행하거나 Skip 가능)

### F5 BNK Dashboard 로드

**경로:**
1. Dashboard 메뉴로 이동
2. F5 BNK Dashboard 로드

**대시보드 구성:**
- **TMM (Data Path)** 시각화
- **ACL** 시각화
- **Red 테넌트** 별도 시각화
- **Blue 테넌트** 별도 시각화

### 트래픽 생성 및 관찰

**Ingress 트래픽 생성:**

```bash
# Red 테넌트 Ingress
docker exec -ti infra-client-1 curl http://198.19.19.100/txt

# Blue 테넌트 Ingress
docker exec -ti infra-client-1 curl http://198.20.20.100/txt
```

**Egress 트래픽 생성:**

```bash
# Red 테넌트 Egress
kubectl exec -ti -n red deploy/nginx-deployment -- curl http://198.51.100.100/txt

# Blue 테넌트 Egress
kubectl exec -ti -n blue deploy/nginx-deployment -- curl http://198.51.100.100/txt
```

**Grafana 대시보드 관찰:**
- 실시간 트래픽 시각화
- Red 및 Blue 테넌트별 통계
- TMM 성능 메트릭
- ACL 규칙 적용 현황

---

## 랩 데모 요약

본 랩에서 다음 사항을 시연했습니다:

### 1. Kubernetes 클러스터 개념 및 세부사항

**네트워킹:**
- CNI 플러그인 (Calico, Multus)
- Service 타입 (ClusterIP, NodePort, LoadBalancer)
- Gateway API

**리소스:**
- Deployment, Service, Endpoints
- Custom Resource Definitions (CRDs)
- Gateway, GatewayClass, L4Route/HTTPRoute

### 2. BIG-IP Next for Kubernetes 설치 및 작동 방식

**설치 구성 요소:**
- Cert-Manager (인증서 관리)
- Gateway API CRDs
- Prometheus & Grafana (모니터링)
- F5 Artifact Registry (FAR) 접근
- Cluster Wide Controller (CWC)
- Orchestrator

**네트워크 설정:**
- VLAN (Ingress용)
- VXLAN (Egress용)
- SNAT Pool
- BGP 라우팅

### 3. 멀티 테넌트 애플리케이션 전달 및 보안

**Ingress:**
- Gateway API를 통한 VIP 노출
- ECMP 기반 로드밸런싱
- 직접 Pod IP 라우팅 (kube-proxy 우회)
- BGP를 통한 경로 광고

**Egress:**
- 테넌트별 SNAT Pool
- VXLAN을 통한 네트워크 세그멘테이션
- 소스 IP 기반 트래픽 식별

**모니터링:**
- Prometheus 메트릭 수집
- Grafana 시각화
- 테넌트별 텔레메트리

---

## 추가 학습 리소스

**공식 문서:**
- [BIG-IP Next for Kubernetes 공식 문서](https://clouddocs.f5.com/bigip-next-for-kubernetes/latest/)
- [Gateway API 공식 사이트](https://gateway-api.sigs.k8s.io/)
- [Kubernetes 네트워킹](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

**F5 리소스:**
- [F5 DevCentral](https://community.f5.com/)
- [F5 Support](https://support.f5.com/)
- [NVIDIA BlueField-3 통합 가이드](https://f5devcentral.github.io/f5-bnk-nvidia-bf3-installations/)

**관련 기술:**
- [Calico CNI](https://docs.tigera.io/calico/latest/about)
- [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)
- [KinD (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [Helm 패키지 매니저](https://helm.sh/)
- [FRRouting](https://docs.frrouting.org/)

---

## 결론

본 랩을 통해 다음을 학습했습니다:

1. **Kubernetes 기초**
   - 클러스터 구성 및 네트워킹
   - CNI 플러그인 작동 방식
   - Service 및 Gateway API

2. **BIG-IP Next for Kubernetes 설치**
   - 전체 설치 프로세스
   - 필수 컴포넌트 구성
   - 멀티 테넌트 네트워크 설정

3. **실제 사용**
   - Gateway API를 통한 애플리케이션 노출
   - Ingress 및 Egress 트래픽 관리
   - 텔레메트리 및 모니터링

**주요 장점:**
- **성능 최적화**: kube-proxy 우회, 직접 Pod IP 라우팅
- **네트워크 세그멘테이션**: 테넌트별 SNAT Pool
- **확장성**: ECMP 기반 로드밸런싱
- **관찰성**: Prometheus/Grafana 통합
- **표준 준수**: Gateway API, OLM Operator

---

**문서 작성일**: 2024년 12월  
**번역자**: Claude (AI Assistant)  
**원문 출처**: F5 BIG-IP Next Training Lab  
**버전**: Latest
