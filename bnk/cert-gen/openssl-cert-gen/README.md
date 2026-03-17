# openssl-cert-gen

These scripts are to generate RabbitMQ server and client certificates. This is similar to https://gitswarm.f5net.com/f5ingress/spk-license/cert-gen but with an additional ability to provide multiple subject alternate names.

This is required for backward compatability between RabbitMQ client (CWC, f5-spk-lic-helper) between v1.6.0 and v1.6.1

In SPK v1.6.0, RabbitMQ clients  tries to reach RabbitMQ server using the URL: amqps://rabbitmq-server.default.svc.cluster.local but 
in SPK v1.6,1 and above RabbitMQ clients reach RabbitMQ server using URL: amqps://rabbitmq-server.default

These scripts generate a RabbitMQ server certificate to have both rabbitmq-server.default.svc.cluster.local and rabbitmq-server.default as subject alternate names. So, when a RabbitMQ client with v1.6.0 tries to reach using **rabbitmq-server.default.svc.cluster.local** is honered and also RabbitMQ client with v1.6.1 that tries to reach using **rabbitmq-server.default** is also honored

Modifications Required:

**Step 1:**
csr.conf is configured for default namespace. Modify this file to include the namespace in which RabbitMQ is deployed.

```
[ alt_names ]
DNS.1 = rabbitmq-server.**default**.svc.cluster.local
DNS.2 = rabbitmq-server.**default**
DNS.3 = rabbitmq-server.**default**.svc
```

**Step 2:**
Similarly update server-cert.conf file 
```
[alt_names]
DNS.1 = rabbitmq-server.**default**.svc.cluster.local
DNS.2 = rabbitmq-server.**default**
DNS.3 = rabbitmq-server.**default**.svc
```

**Step 3:**
Run the script to generate certificates
```sh gen-cert.sh```

**Step 4:**
Run script to generate yaml files
```sh gen-yaml.sh```



