# Cafe 应用程序 - HTTP/HTTPS 部署

## 🚀 快速入门

### 1. 生成并应用 TLS 证书

```bash
chmod +x create-tls-cert.sh
./create-tls-cert.sh
kubectl apply -f cafe-tls-secret.yaml
```

### 2. 部署应用程序

```bash
kubectl apply -f cafe-app.yaml
```

### 3. 测试

```bash
# HTTP (端口 80)
curl http://cafe.example.com/coffee
curl http://cafe.example.com/tea

# HTTPS (端口 443)
curl -k https://cafe.example.com/coffee
curl -k https://cafe.example.com/tea
```

## 📁 文件结构

```
.
├── cafe-app.yaml                      # 主应用程序清单 (包含 Ingress)
├── create-tls-cert.sh                 # TLS 证书生成脚本
├── cafe-app-with-certmanager.yaml     # cert-manager 使用版本 (建议生产环境使用)
├── DEPLOYMENT-GUIDE.md                # 详细部署指南
└── README.md                          # 本文件
```

## 📋 主要变更事项

- ✅ Service Type: NodePort → ClusterIP
- ✅ 添加 Ingress: 支持 HTTP(80) 及 HTTPS(443)
- ✅ TLS/SSL: 支持自签名证书
- ✅ 基于路径的路由: `/coffee`, `/tea`

## 🔐 安全注意事项

⚠️ **自签名证书仅用于开发/测试！**

在生产环境中：
- 使用 cert-manager + Let's Encrypt (参见 `cafe-app-with-certmanager.yaml`)
- 或使用商业 CA 证书

## 📖 详细文档

完整指南请参阅 [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)

## 🛠️ 前提条件

- Kubernetes 集群
- Ingress Controller (建议使用 NGINX)
- kubectl
- openssl

## 💡 帮助

如果遇到问题，请查看 [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) 的故障排除部分。
