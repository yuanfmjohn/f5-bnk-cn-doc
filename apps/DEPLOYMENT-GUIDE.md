# Cafe 应用程序部署指南 (HTTP/HTTPS)

本指南介绍了如何通过 80(HTTP) 和 443(HTTPS) 端口提供 cafe 应用程序服务的方法。

## 📋 前提条件

1. **Kubernetes 集群** (建议 v1.19 或更高版本)
2. **安装 Ingress Controller** (建议使用 NGINX Ingress Controller)
3. **kubectl** 命令行工具
4. **openssl** (用于生成 TLS 证书)

## 🔧 安装 Ingress Controller

### 安装 NGINX Ingress Controller (若未安装)

```bash
# 使用 Helm 时
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx

# 或使用 kubectl 时
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

确认安装:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## 🔐 第 1 步: 生成自签名 TLS 证书

### 方法 1: 使用脚本 (推荐)

```bash
# 赋予执行权限
chmod +x create-tls-cert.sh

# 以默认域名 (cafe.example.com) 运行
./create-tls-cert.sh

# 或以自定义域名运行
./create-tls-cert.sh mycafe.local
```

### 方法 2: 手动生成

```bash
# 1. 生成私钥
openssl genrsa -out cafe-tls.key 2048

# 2. 生成证书签名请求 (CSR)
openssl req -new -key cafe-tls.key -out cafe-tls.csr \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=MyOrg/OU=IT/CN=cafe.example.com"

# 3. 生成自签名证书 (有效期 1 年)
openssl x509 -req -days 365 -in cafe-tls.csr \
  -signkey cafe-tls.key -out cafe-tls.crt

# 4. 创建 Kubernetes Secret
kubectl create secret tls cafe-tls-secret \
  --cert=cafe-tls.crt \
  --key=cafe-tls.key
```

## 🚀 第 2 步: 部署应用程序

### 应用 TLS Secret (使用脚本时)

```bash
kubectl apply -f cafe-tls-secret.yaml
```

### 应用应用程序清单

```bash
kubectl apply -f cafe-app.yaml
```

## ✅ 第 3 步: 确认部署

### 确认资源

```bash
# 确认 Pod 状态
kubectl get pods

# 确认 Service
kubectl get svc

# 确认 Ingress
kubectl get ingress cafe-ingress

# Ingress 详细信息
kubectl describe ingress cafe-ingress
```

### 确认 Ingress 外部 IP

```bash
kubectl get ingress cafe-ingress -o wide
```

输出示例:
```
NAME           CLASS   HOSTS              ADDRESS        PORTS     AGE
cafe-ingress   nginx   cafe.example.com   34.123.45.67   80, 443   2m
```

## 🌐 第 4 步: 设置域名

### 修改本地测试用的 hosts 文件

```bash
# 确认 Ingress 的外部 IP
INGRESS_IP=$(kubectl get ingress cafe-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 添加到 hosts 文件 (Linux/Mac)
echo "$INGRESS_IP cafe.example.com" | sudo tee -a /etc/hosts

# Windows 情况下
# 以管理员权限打开 C:\Windows\System32\drivers\etc\hosts 文件
# 添加 <INGRESS_IP> cafe.example.com
```

## 🧪 第 5 步: 测试

### HTTP 测试 (端口 80)

```bash
# Coffee 服务
curl http://cafe.example.com/coffee

# Tea 服务
curl http://cafe.example.com/tea
```

### HTTPS 测试 (端口 443)

由于是自签名证书，使用 `-k` 选项忽略证书验证:

```bash
# Coffee 服务
curl -k https://cafe.example.com/coffee

# Tea 服务
curl -k https://cafe.example.com/tea
```

### 浏览器测试

1. 在浏览器中访问:
   - `http://cafe.example.com/coffee`
   - `https://cafe.example.com/tea`

2. 访问 HTTPS 时如果出现安全警告:
   - Chrome: 点击 "高级" → "继续前往 cafe.example.com (不安全)"
   - Firefox: 点击 "高级" → "接受风险并继续"

## 📊 主要变更事项

### 相对原版的变更部分:

1. **Service Type**: `NodePort` → `ClusterIP`
   - 由于 Ingress 处理外部访问，故更改为 ClusterIP

2. **添加 Ingress 资源**:
   - HTTP(80) 及 HTTPS(443) 流量路由
   - 基于路径的路由: `/coffee`, `/tea`

3. **TLS 设置**:
   - 支持使用自签名证书的 HTTPS
   - 通过 `cafe-tls-secret` Secret 管理证书

## 🔍 故障排除

### Ingress 未分配外部 IP 的情况

```bash
# 确认 Ingress Controller Service
kubectl get svc -n ingress-nginx

# 如果 LoadBalancer 类型处于 Pending 状态，可能不是云环境
# 在 Minikube/Kind 等本地环境中，请使用以下方法:

# Minikube
minikube tunnel

# Kind (使用端口转发)
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 8443:443
# 之后通过 http://localhost:8080/coffee 访问
```

### 证书错误

```bash
# 确认 Secret
kubectl get secret cafe-tls-secret
kubectl describe secret cafe-tls-secret

# 重新生成 Secret
kubectl delete secret cafe-tls-secret
./create-tls-cert.sh
kubectl apply -f cafe-tls-secret.yaml
```

### 503 Service Unavailable 错误

```bash
# 确认 Pod 状态
kubectl get pods

# 确认 Pod 日志
kubectl logs -l app=coffee
kubectl logs -l app=tea

# 确认 Service 端点 (Endpoints)
kubectl get endpoints coffee-svc tea-svc
```

## 🎯 生产环境建议事项

1. **使用有效的 TLS 证书**:
   - Let's Encrypt (使用 cert-manager)
   - 商业 CA 证书

2. **安装 cert-manager** (自动管理证书):
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

3. **设置资源限制**:
   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
     limits:
       cpu: 200m
       memory: 256Mi
   ```

4. **添加健康检查 (Health Check)**:
   ```yaml
   livenessProbe:
     httpGet:
       path: /
       port: 8080
   readinessProbe:
     httpGet:
       path: /
       port: 8080
   ```

## 📝 备注事项

- 自签名证书仅用于开发/测试环境
- 在生产环境中，请使用受信任 CA 颁发的证书
- 根据 Ingress Controller 的种类 (NGINX, Traefik, HAProxy 等)，annotations 可能会有所不同
- 请根据实际环境修改域名

## 🔗 有用链接

- [Kubernetes Ingress 文档](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager 文档](https://cert-manager.io/docs/)
