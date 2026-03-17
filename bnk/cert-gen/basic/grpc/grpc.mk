# Makefile chunk for handling gRPC and cert/key related tasks

# Used in cert/key generation for development and testing environments
CLIENT_SERVICE_ACCOUNT=f5-ing-demo-f5ingress
CONTROLLER_NAMESPACE=f5-spk

SECRETS_DIR=$(BASE_DIR)
SECRET_KEY_FILE=$(SECRETS_DIR)/keys-secret.yaml
SECRET_CERT_FILE=$(SECRETS_DIR)/certs-secret.yaml
SERVER_CERT=grpc-svc.crt
CLIENT_CERT=$(CLIENT_SERVICE_ACCOUNT).crt
ROOT_CERT=ca_root.crt
SERVER_KEY=grpc-svc.key
SERVER_CSR=grpc-svc.csr
VALIDATION_SERVER_CERT=validation-svc.crt
VALIDATION_SERVER_KEY=validation-svc.key
VALIDATION_SERVER_CSR=validation-svc.csr
PCCD_CLIENT_CSR=grpc-pccd-client.csr
PCCD_CLIENT_KEY=grpc-pccd-client.key
PCCD_CLIENT_CERT=grpc-pccd-client.crt
IPSD_CLIENT_CSR=grpc-ipsd-client.csr
IPSD_CLIENT_KEY=grpc-ipsd-client.key
IPSD_CLIENT_CERT=grpc-ipsd-client.crt
DOWNLOADER_CLIENT_CSR=grpc-downloader-client.csr
DOWNLOADER_CLIENT_KEY=grpc-downloader-client.key
DOWNLOADER_CLIENT_CERT=grpc-downloader-client.crt
OTEL_CLIENT_CSR=grpc-otel-client.csr
OTEL_CLIENT_KEY=grpc-otel-client.key
OTEL_CLIENT_CERT=grpc-otel-client.crt
OTEL_SERVER_CSR=grpc-otel-server.csr
OTEL_SERVER_KEY=grpc-otel-server.key
OTEL_SERVER_CERT=grpc-otel-server.crt
DNSX_SERVER_CSR=grpc-dnsx-server.csr
DNSX_SERVER_KEY=grpc-dnsx-server.key
DNSX_SERVER_CERT=grpc-dnsx-server.crt
GSLB_SERVER_CSR=grpc-gslb-server.csr
GSLB_SERVER_KEY=grpc-gslb-server.key
GSLB_SERVER_CERT=grpc-gslb-server.crt
GSLB_CLIENT_CSR=grpc-gslb-client.csr
GSLB_CLIENT_KEY=grpc-gslb-client.key
GSLB_CLIENT_CERT=grpc-gslb-client.crt
GSLB_PROBE_AGENT_SERVER_CSR=grpc-gslb-probe-agent-server.csr
GSLB_PROBE_AGENT_SERVER_KEY=grpc-gslb-probe-agent-server.key
GSLB_PROBE_AGENT_SERVER_CERT=grpc-gslb-probe-agent-server.crt
GSLB_PROBE_AGENT_CLIENT_CSR=grpc-gslb-probe-agent-client.csr
GSLB_PROBE_AGENT_CLIENT_KEY=grpc-gslb-probe-agent-client.key
GSLB_PROBE_AGENT_CLIENT_CERT=grpc-gslb-probe-agent-client.crt
FQDN_CSR=f5-fqdn-resolver.csr
FQDN_KEY=f5-fqdn-resolver.key
FQDN_CERT=f5-fqdn-resolver.crt
CLIENT_CSR=client.csr
CLIENT_KEY=f5-ing-demo-f5ingress.key
ROOT_KEY=priv.key

SCRIPTS_DIR=/scripts/grpc
VALIDATION_SCRIPTS_DIR=scripts/validation
SSL_WORKING_DIR=$(CNF_WORKING_DIR)/ssl
CA_FILES_DIR=$(SSL_WORKING_DIR)/ca
CA_SECRETS_DIR=$(CA_FILES_DIR)/secrets
CA_CERTS_DIR=$(CA_FILES_DIR)/certs
SERVER_DIR=$(SSL_WORKING_DIR)/server
SERVER_SECRETS_DIR=$(SERVER_DIR)/secrets
SERVER_CERTS_DIR=$(SERVER_DIR)/certs
SERVER_EXT=grpc/grpc-service.ext
VALIDATION_SERVER_EXT=grpc/validation-service.ext
FQDN_EXT=grpc/f5-fqdn-resolver.ext
CLIENT_DIR=$(SSL_WORKING_DIR)/client
CLIENT_SECRETS_DIR=$(CLIENT_DIR)/secrets
CLIENT_CERTS_DIR=$(CLIENT_DIR)/certs
PCCD_CLIENT_DIR=$(SSL_WORKING_DIR)/pccd-client
PCCD_CLIENT_SECRETS_DIR=$(PCCD_CLIENT_DIR)/secrets
PCCD_CLIENT_CERTS_DIR=$(PCCD_CLIENT_DIR)/certs
IPSD_CLIENT_DIR=$(SSL_WORKING_DIR)/ipsd-client
IPSD_CLIENT_SECRETS_DIR=$(IPSD_CLIENT_DIR)/secrets
IPSD_CLIENT_CERTS_DIR=$(IPSD_CLIENT_DIR)/certs
DOWNLOADER_CLIENT_DIR=$(SSL_WORKING_DIR)/downloader-client
DOWNLOADER_CLIENT_SECRETS_DIR=$(DOWNLOADER_CLIENT_DIR)/secrets
DOWNLOADER_CLIENT_CERTS_DIR=$(DOWNLOADER_CLIENT_DIR)/certs
OTEL_CLIENT_DIR=$(SSL_WORKING_DIR)/otel-client
OTEL_CLIENT_SECRETS_DIR=$(OTEL_CLIENT_DIR)/secrets
OTEL_CLIENT_CERTS_DIR=$(OTEL_CLIENT_DIR)/certs
OTEL_SERVER_DIR=$(SSL_WORKING_DIR)/otel-server
OTEL_SERVER_SECRETS_DIR=$(OTEL_SERVER_DIR)/secrets
OTEL_SERVER_CERTS_DIR=$(OTEL_SERVER_DIR)/certs
DNSX_SERVER_DIR=$(SSL_WORKING_DIR)/dnsx-server
DNSX_SERVER_SECRETS_DIR=$(DNSX_SERVER_DIR)/secrets
DNSX_SERVER_CERTS_DIR=$(DNSX_SERVER_DIR)/certs
GSLB_SERVER_DIR=$(SSL_WORKING_DIR)/gslb-server
GSLB_SERVER_SECRETS_DIR=$(GSLB_SERVER_DIR)/secrets
GSLB_SERVER_CERTS_DIR=$(GSLB_SERVER_DIR)/certs
GSLB_CLIENT_DIR=$(SSL_WORKING_DIR)/gslb-client
GSLB_CLIENT_SECRETS_DIR=$(GSLB_CLIENT_DIR)/secrets
GSLB_CLIENT_CERTS_DIR=$(GSLB_CLIENT_DIR)/certs
GSLB_PROBE_AGENT_SERVER_DIR=$(SSL_WORKING_DIR)/gslb-probe-agent-server
GSLB_PROBE_AGENT_SERVER_SECRETS_DIR=$(GSLB_PROBE_AGENT_SERVER_DIR)/secrets
GSLB_PROBE_AGENT_SERVER_CERTS_DIR=$(GSLB_PROBE_AGENT_SERVER_DIR)/certs
GSLB_PROBE_AGENT_CLIENT_DIR=$(SSL_WORKING_DIR)/gslb-probe-agent-client
GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR=$(GSLB_PROBE_AGENT_CLIENT_DIR)/secrets
GSLB_PROBE_AGENT_CLIENT_CERTS_DIR=$(GSLB_PROBE_AGENT_CLIENT_DIR)/certs
FQDN_DIR=$(SSL_WORKING_DIR)/f5-fqdn-resolver
FQDN_SECRETS_DIR=$(FQDN_DIR)/secrets
FQDN_CERTS_DIR=$(FQDN_DIR)/certs
VALIDATION_SERVER_DIR=$(SSL_WORKING_DIR)/validation-server
VALIDATION_SERVER_SECRETS_DIR=$(VALIDATION_SERVER_DIR)/secrets
VALIDATION_SERVER_CERTS_DIR=$(VALIDATION_SERVER_DIR)/certs
F5CA_CERT_SUBJ="/C=US/ST=Washington/L=Seattle/O=F5 Networks/OU=PD/CN=ca"
F5_CERT_SUBJ="/C=US/ST=Washington/L=Seattle/O=F5 Networks/OU=PD/CN=f5net.com"
CLIENT_SERIAL=101
CLIENT_EXT=grpc/client.ext


.PHONY: gen-secrets gen-ca-secrets gen-server-secrets gen-client-secrets gen-pccd-client-secrets gen-ipsd-client-secrets gen-downloader-client-secrets gen-otel-client-secrets gen-otel-server-secrets gen-dnsx-server-secrets gen-gslb-client-secrets gen-gslb-server-secrets gen-gslb-probe-agent-client-secrets gen-gslb-probe-agent-server-secrets gen-fqdn-secrets gen-secrets-dir gen-validation-server-secrets
.PHONY: clean-secrets clean-ca-secrets clean-server-secrets clean-client-secrets clean-pccd-client-secrets clean-ipsd-client-secrets clean-downloader-client-secrets clean-otel-client-secrets clean-otel-server-secrets clean-dnsx-server-secrets clean-gslb-client-secrets clean-gslb-server-secrets clean-gslb-probe-agent-client-secrets clean-gslb-probe-agent-server-secrets clean-fqdn-secrets clean-secret-yamls clean-validation-server-secrets
clean-secrets: clean-ca-secrets clean-server-secrets clean-client-secrets clean-pccd-client-secrets clean-ipsd-client-secrets clean-downloader-client-secrets clean-otel-client-secrets clean-otel-server-secrets clean-dnsx-server-secrets clean-gslb-client-secrets clean-gslb-server-secrets clean-gslb-probe-agent-client-secrets clean-gslb-probe-agent-server-secrets clean-fqdn-secrets clean-secret-yamls clean-validation-server-secrets

clean-ca-secrets:
	@printf '\e[1mCleaning $(CA_SECRETS_DIR)\e[0m\n'
	@printf '\e[1mBASEDIR $(BASE_DIR)\e[0m\n'
	rm -rf $(CA_SECRETS_DIR)
	@printf '\e[1mCleaning $(CA_CERTS_DIR)\e[0m\n'
	rm -rf $(CA_CERTS_DIR)

clean-validation-server-secrets:
	@printf '\e[1mCleaning $(VALIDATION_SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(VALIDATION_SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(VALIDATION_SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(VALIDATION_SERVER_CERTS_DIR)

clean-server-secrets:
	@printf '\e[1mCleaning $(SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(SERVER_CERTS_DIR)

clean-client-secrets:
	@printf '\e[1mCleaning $(CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(CLIENT_CERTS_DIR)

clean-pccd-client-secrets:
	@printf '\e[1mCleaning $(PCCD_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(PCCD_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(PCCD_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(PCCD_CLIENT_CERTS_DIR)

clean-ipsd-client-secrets:
	@printf '\e[1mCleaning $(IPSD_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(IPSD_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(IPSD_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(IPSD_CLIENT_CERTS_DIR)

clean-downloader-client-secrets:
	@printf '\e[1mCleaning $(DOWNLOADER_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(DOWNLOADER_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(DOWNLOADER_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(DOWNLOADER_CLIENT_CERTS_DIR)

clean-otel-client-secrets:
	@printf '\e[1mCleaning $(OTEL_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(OTEL_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(OTEL_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(OTEL_CLIENT_CERTS_DIR)

clean-otel-server-secrets:
	@printf '\e[1mCleaning $(OTEL_SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(OTEL_SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(OTEL_SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(OTEL_SERVER_CERTS_DIR)

clean-dnsx-server-secrets:
	@printf '\e[1mCleaning $(DNSX_SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(DNSX_SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(DNSX_SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(DNSX_SERVER_CERTS_DIR)

clean-gslb-client-secrets:
	@printf '\e[1mCleaning $(GSLB_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(GSLB_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(GSLB_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(GSLB_CLIENT_CERTS_DIR)

clean-gslb-server-secrets:
	@printf '\e[1mCleaning $(GSLB_SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(GSLB_SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(GSLB_SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(GSLB_SERVER_CERTS_DIR)

clean-gslb-probe-agent-client-secrets:
	@printf '\e[1mCleaning $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)\e[0m\n'
	rm -rf $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)
	@printf '\e[1mCleaning $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)\e[0m\n'
	rm -rf $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)

clean-gslb-probe-agent-server-secrets:
	@printf '\e[1mCleaning $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)\e[0m\n'
	rm -rf $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)
	@printf '\e[1mCleaning $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)\e[0m\n'
	rm -rf $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)

clean-fqdn-secrets:
	@printf '\e[1mCleaning $(FQDN_SECRETS_DIR)\e[0m\n'
	rm -rf $(FQDN_SECRETS_DIR)
	@printf '\e[1mCleaning $(FQDN_CERTS_DIR)\e[0m\n'
	rm -rf $(FQDN_CERTS_DIR)

clean-secret-yamls:
	rm -rf $(SECRET_CERT_FILE)
	rm -rf $(SECRET_KEY_FILE)

gen-secrets: gen-secrets-dir gen-ca-secrets gen-server-secrets gen-client-secrets gen-pccd-client-secrets gen-ipsd-client-secrets gen-downloader-client-secrets gen-otel-client-secrets gen-otel-server-secrets gen-dnsx-server-secrets gen-gslb-client-secrets gen-gslb-server-secrets gen-gslb-probe-agent-client-secrets gen-gslb-probe-agent-server-secrets gen-fqdn-secrets gen-validation-server-secrets

gen-secrets-dir:
	@printf '\e[1mCreating $(SECRETS_DIR)\e[0m\n'
	mkdir -p $(SECRETS_DIR)

gen-ca-secrets: clean-ca-secrets
	@printf '\e[1mCreating $(CA_SECRETS_DIR)\e[0m\n'
	mkdir -p $(CA_SECRETS_DIR)
	@printf '\e[1mCreating $(CA_CERTS_DIR)\e[0m\n'
	mkdir -p $(CA_CERTS_DIR)
	@printf '\e[1mGenerating CA Private Key - $(CA_SECRETS_DIR)/$(ROOT_KEY)\e[0m\n'
	openssl genrsa -out $(CA_SECRETS_DIR)/$(ROOT_KEY) 4096
	@printf '\e[1mGenerating CA Cert - $(CA_CERTS_DIR)/$(ROOT_CERT)\e[0m\n'
	openssl req -x509 -new -nodes -key $(CA_SECRETS_DIR)/$(ROOT_KEY) -sha256 -days 30 -out $(CA_CERTS_DIR)/$(ROOT_CERT) -subj $(F5CA_CERT_SUBJ)

gen-validation-server-secrets: clean-validation-server-secrets
	@printf '\e[1mCreating $(VALIDATION_SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(VALIDATION_SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(VALIDATION_SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(VALIDATION_SERVER_CERTS_DIR)
	@printf '\e[1mGenerating Validation Server Private Key - $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_KEY) 4096
	@printf '\e[1mGenerating Server CSR - $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_CSR)\e[0m\n'
	openssl req -new -key $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_KEY) -out $(VALIDATION_SERVER_CERTS_DIR)/$(VALIDATION_SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Server Cert - $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_CERT)\e[0m\n'
	@echo "[req_ext]" > $(VALIDATION_SERVER_EXT)
	@echo "subjectAltName = @alt_names" >> $(VALIDATION_SERVER_EXT)
	@echo "[alt_names]" >> $(VALIDATION_SERVER_EXT)
	@echo "DNS.1 = "$(SERVER_ALT_NAME) >> $(VALIDATION_SERVER_EXT)
	openssl x509 -req -in $(VALIDATION_SERVER_CERTS_DIR)/$(VALIDATION_SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -CAcreateserial -out $(VALIDATION_SERVER_CERTS_DIR)/$(VALIDATION_SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(VALIDATION_SERVER_EXT)

gen-server-secrets: clean-server-secrets
	@printf '\e[1mCreating $(SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(SERVER_CERTS_DIR)
	@printf '\e[1mGenerating Server Private Key - $(SERVER_SECRETS_DIR)/$(SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(SERVER_SECRETS_DIR)/$(SERVER_KEY) 4096
	@printf '\e[1mGenerating Server CSR - $(SERVER_SECRETS_DIR)/$(SERVER_CSR)\e[0m\n'
	openssl req -new -key $(SERVER_SECRETS_DIR)/$(SERVER_KEY) -out $(SERVER_CERTS_DIR)/$(SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Server Cert - $(SERVER_SECRETS_DIR)/$(SERVER_CERT)\e[0m\n'
	openssl x509 -req -in $(SERVER_CERTS_DIR)/$(SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -CAcreateserial -out $(SERVER_CERTS_DIR)/$(SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(SERVER_EXT)

gen-client-secrets: clean-client-secrets
	@printf '\e[1mCreating $(CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating Client Private Key - $(CLIENT_SECRETS_DIR)/$(CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(CLIENT_SECRETS_DIR)/$(CLIENT_KEY) 4096
	@printf '\e[1mGenerating Client CSR - $(CLIENT_SECRETS_DIR)/$(CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(CLIENT_SECRETS_DIR)/$(CLIENT_KEY) -out $(CLIENT_CERTS_DIR)/$(CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Client Cert - $(CLIENT_SECRETS_DIR)/$(CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(CLIENT_CERTS_DIR)/$(CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(CLIENT_CERTS_DIR)/$(CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-pccd-client-secrets: clean-pccd-client-secrets
	@printf '\e[1mCreating $(PCCD_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(PCCD_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(PCCD_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(PCCD_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating Client Private Key - $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_KEY) 4096
	@printf '\e[1mGenerating Client CSR - $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_KEY) -out $(PCCD_CLIENT_CERTS_DIR)/$(PCCD_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Client Cert - $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(PCCD_CLIENT_CERTS_DIR)/$(PCCD_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(PCCD_CLIENT_CERTS_DIR)/$(PCCD_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-ipsd-client-secrets: clean-ipsd-client-secrets
	@printf '\e[1mCreating $(IPSD_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(IPSD_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(IPSD_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(IPSD_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating Client Private Key - $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_KEY) 4096
	@printf '\e[1mGenerating Client CSR - $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_KEY) -out $(IPSD_CLIENT_CERTS_DIR)/$(IPSD_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Client Cert - $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(IPSD_CLIENT_CERTS_DIR)/$(IPSD_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(IPSD_CLIENT_CERTS_DIR)/$(IPSD_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-downloader-client-secrets: clean-downloader-client-secrets
	@printf '\e[1mCreating $(DOWNLOADER_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(DOWNLOADER_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(DOWNLOADER_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(DOWNLOADER_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating Client Private Key - $(DOWNLOADER_SECRETS_DIR)/$(DOWNLOADER_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(DOWNLOADER_CLIENT_SECRETS_DIR)/$(DOWNLOADER_CLIENT_KEY) 4096
	@printf '\e[1mGenerating Client CSR - $(DOWNLOADER_CLIENT_SECRETS_DIR)/$(DOWNLOADER_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(DOWNLOADER_CLIENT_SECRETS_DIR)/$(DOWNLOADER_CLIENT_KEY) -out $(DOWNLOADER_CLIENT_CERTS_DIR)/$(DOWNLOADER_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating Client Cert - $(DOWNLOADER_CLIENT_SECRETS_DIR)/$(DOWNLOADER_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(DOWNLOADER_CLIENT_CERTS_DIR)/$(DOWNLOADER_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(DOWNLOADER_CLIENT_CERTS_DIR)/$(DOWNLOADER_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-otel-client-secrets: clean-otel-client-secrets
	@printf '\e[1mCreating $(OTEL_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(OTEL_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(OTEL_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(OTEL_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating OTEL Client Private Key - $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_KEY) 4096
	@printf '\e[1mGenerating OTEL Client CSR - $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_KEY) -out $(OTEL_CLIENT_CERTS_DIR)/$(OTEL_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating OTEL Client Cert - $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(OTEL_CLIENT_CERTS_DIR)/$(OTEL_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(OTEL_CLIENT_CERTS_DIR)/$(OTEL_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-otel-server-secrets: clean-otel-server-secrets
	@printf '\e[1mCreating $(OTEL_SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(OTEL_SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(OTEL_SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(OTEL_SERVER_CERTS_DIR)
	@printf '\e[1mGenerating OTEL Server Private Key - $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_KEY) 4096
	@printf '\e[1mGenerating OTEL Server CSR - $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_CSR)\e[0m\n'
	openssl req -new -key $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_KEY) -out $(OTEL_SERVER_CERTS_DIR)/$(OTEL_SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating OTEL Server Cert - $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_CERT)\e[0m\n'
	openssl x509 -req -in $(OTEL_SERVER_CERTS_DIR)/$(OTEL_SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(OTEL_SERVER_CERTS_DIR)/$(OTEL_SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(SERVER_EXT)

gen-dnsx-server-secrets: clean-dnsx-server-secrets
	@printf '\e[1mCreating $(DNSX_SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(DNSX_SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(DNSX_SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(DNSX_SERVER_CERTS_DIR)
	@printf '\e[1mGenerating DNSX Server Private Key - $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_KEY) 4096
	@printf '\e[1mGenerating DNSX Server CSR - $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_CSR)\e[0m\n'
	openssl req -new -key $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_KEY) -out $(DNSX_SERVER_CERTS_DIR)/$(DNSX_SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating DNSX Server Cert - $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_CERT)\e[0m\n'
	openssl x509 -req -in $(DNSX_SERVER_CERTS_DIR)/$(DNSX_SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(DNSX_SERVER_CERTS_DIR)/$(DNSX_SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(SERVER_EXT)

gen-gslb-client-secrets: clean-gslb-client-secrets
	@printf '\e[1mCreating $(GSLB_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(GSLB_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(GSLB_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(GSLB_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating GSLB Client Private Key - $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_KEY) 4096
	@printf '\e[1mGenerating GSLB Client CSR - $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_KEY) -out $(GSLB_CLIENT_CERTS_DIR)/$(GSLB_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating GSLB Client Cert - $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(GSLB_CLIENT_CERTS_DIR)/$(GSLB_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(GSLB_CLIENT_CERTS_DIR)/$(GSLB_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-gslb-server-secrets: clean-gslb-server-secrets
	@printf '\e[1mCreating $(GSLB_SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(GSLB_SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(GSLB_SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(GSLB_SERVER_CERTS_DIR)
	@printf '\e[1mGenerating GSLB Server Private Key - $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_KEY) 4096
	@printf '\e[1mGenerating GSLB Server CSR - $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_CSR)\e[0m\n'
	openssl req -new -key $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_KEY) -out $(GSLB_SERVER_CERTS_DIR)/$(GSLB_SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating GSLB Server Cert - $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_CERT)\e[0m\n'
	openssl x509 -req -in $(GSLB_SERVER_CERTS_DIR)/$(GSLB_SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(GSLB_SERVER_CERTS_DIR)/$(GSLB_SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(SERVER_EXT)

gen-gslb-probe-agent-client-secrets: clean-gslb-probe-agent-client-secrets
	@printf '\e[1mCreating $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)\e[0m\n'
	mkdir -p $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)
	@printf '\e[1mCreating $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)\e[0m\n'
	mkdir -p $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)
	@printf '\e[1mGenerating GSLB Probe Agent Client Private Key - $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_KEY)\e[0m\n'
	openssl genrsa -out $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_KEY) 4096
	@printf '\e[1mGenerating GSLB Probe Agent Client CSR - $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CSR)\e[0m\n'
	openssl req -new -key $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_KEY) -out $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating GSLB Probe Agent Client Cert - $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CERT)\e[0m\n'
	openssl x509 -req -in $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CERT) -extensions req_ext -days 365 -sha256 -extfile $(CLIENT_EXT)

gen-gslb-probe-agent-server-secrets: clean-gslb-probe-agent-server-secrets
	@printf '\e[1mCreating $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)\e[0m\n'
	mkdir -p $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)
	@printf '\e[1mCreating $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)\e[0m\n'
	mkdir -p $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)
	@printf '\e[1mGenerating GSLB Probe Agent Server Private Key - $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_KEY)\e[0m\n'
	openssl genrsa -out $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_KEY) 4096
	@printf '\e[1mGenerating GSLB Probe Agent Server CSR - $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CSR)\e[0m\n'
	openssl req -new -key $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_KEY) -out $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating GSLB Probe Agent Server Cert - $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CERT)\e[0m\n'
	openssl x509 -req -in $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CERT) -extensions req_ext -days 365 -sha256 -extfile $(SERVER_EXT)

gen-fqdn-secrets: clean-fqdn-secrets
	@printf '\e[1mCreating $(FQDN_SECRETS_DIR)\e[0m\n'
	mkdir -p $(FQDN_SECRETS_DIR)
	@printf '\e[1mCreating $(FQDN_CERTS_DIR)\e[0m\n'
	mkdir -p $(FQDN_CERTS_DIR)
	@printf '\e[1mGenerating F5 FQDN Resolver Private Key - $(FQDN_SECRETS_DIR)/$(FQDN_KEY)\e[0m\n'
	openssl genrsa -out $(FQDN_SECRETS_DIR)/$(FQDN_KEY) 4096
	@printf '\e[1mGenerating F5 FQDN Resolver CSR - $(FQDN_SECRETS_DIR)/$(FQDN_CSR)\e[0m\n'
	openssl req -new -key $(FQDN_SECRETS_DIR)/$(FQDN_KEY) -out $(FQDN_CERTS_DIR)/$(FQDN_CSR) -subj $(F5_CERT_SUBJ)
	@printf '\e[1mGenerating F5 FQDN Resolver Cert - $(FQDN_SECRETS_DIR)/$(FQDN_CERT)\e[0m\n'
	openssl x509 -req -in $(FQDN_CERTS_DIR)/$(FQDN_CSR) -CA $(CA_CERTS_DIR)/$(ROOT_CERT) -CAkey $(CA_SECRETS_DIR)/$(ROOT_KEY) -set_serial $(CLIENT_SERIAL) -outform PEM -out $(FQDN_CERTS_DIR)/$(FQDN_CERT) -days 365 -sha256 -extfile $(FQDN_EXT)

.PHONY: create-cert-secrets-yaml
create-cert-secrets-yaml:
	@echo Generating $(SECRET_CERT_FILE)
	@echo "apiVersion: v1" > $(SECRET_CERT_FILE)
	@echo "kind: Secret" >> $(SECRET_CERT_FILE)
	@echo "metadata:" >> $(SECRET_CERT_FILE)
	@echo " name: certs-secret" >> $(SECRET_CERT_FILE)
	@echo "data:" >> $(SECRET_CERT_FILE)
	@echo " $(SERVER_CERT): $$(cat $(SERVER_CERTS_DIR)/$(SERVER_CERT) | base64 -w 0)"  >> $(SECRET_CERT_FILE)
	@echo " $(ROOT_CERT): $$(cat $(CA_CERTS_DIR)/$(ROOT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(CLIENT_CERT): $$(cat $(CLIENT_CERTS_DIR)/$(CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(PCCD_CLIENT_CERT): $$(cat $(PCCD_CLIENT_CERTS_DIR)/$(PCCD_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(IPSD_CLIENT_CERT): $$(cat $(IPSD_CLIENT_CERTS_DIR)/$(IPSD_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(DOWNLOADER_CLIENT_CERT): $$(cat $(DOWNLOADER_CLIENT_CERTS_DIR)/$(DOWNLOADER_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(OTEL_CLIENT_CERT): $$(cat $(OTEL_CLIENT_CERTS_DIR)/$(OTEL_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(OTEL_SERVER_CERT): $$(cat $(OTEL_SERVER_CERTS_DIR)/$(OTEL_SERVER_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(DNSX_SERVER_CERT): $$(cat $(DNSX_SERVER_CERTS_DIR)/$(DNSX_SERVER_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(GSLB_SERVER_CERT): $$(cat $(GSLB_SERVER_CERTS_DIR)/$(GSLB_SERVER_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(GSLB_CLIENT_CERT): $$(cat $(GSLB_CLIENT_CERTS_DIR)/$(GSLB_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(GSLB_PROBE_AGENT_SERVER_CERT): $$(cat $(GSLB_PROBE_AGENT_SERVER_CERTS_DIR)/$(GSLB_PROBE_AGENT_SERVER_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(GSLB_PROBE_AGENT_CLIENT_CERT): $$(cat $(GSLB_PROBE_AGENT_CLIENT_CERTS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(FQDN_CERT): $$(cat $(FQDN_CERTS_DIR)/$(FQDN_CERT) | base64 -w 0)" >> $(SECRET_CERT_FILE)
	@echo " $(VALIDATION_SERVER_CERT): $$(cat $(VALIDATION_SERVER_CERTS_DIR)/$(VALIDATION_SERVER_CERT) | base64 -w 0)"  >> $(SECRET_CERT_FILE)


## Create certs and keys using ssl_ca and place them in 'secrets' folder
## i.e. secrets/grpc-svc.key, secrets/ca_root.crt
.PHONY: create-key-secrets-yaml
create-key-secrets-yaml:
	@echo Generating $(SECRET_KEY_FILE)
	@echo "apiVersion: v1" > $(SECRET_KEY_FILE)
	@echo "kind: Secret" >> $(SECRET_KEY_FILE)
	@echo "metadata:" >> $(SECRET_KEY_FILE)
	@echo " name: keys-secret" >> $(SECRET_KEY_FILE)
	@echo "data:" >> $(SECRET_KEY_FILE)
	@echo " $(SERVER_KEY): $$(cat $(SERVER_SECRETS_DIR)/$(SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(ROOT_KEY): $$(cat $(CA_SECRETS_DIR)/$(ROOT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(CLIENT_KEY): $$(cat $(CLIENT_SECRETS_DIR)/$(CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(PCCD_CLIENT_KEY): $$(cat $(PCCD_CLIENT_SECRETS_DIR)/$(PCCD_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(IPSD_CLIENT_KEY): $$(cat $(IPSD_CLIENT_SECRETS_DIR)/$(IPSD_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(DOWNLOADER_CLIENT_KEY): $$(cat $(DOWNLOADER_CLIENT_SECRETS_DIR)/$(DOWNLOADER_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(OTEL_CLIENT_KEY): $$(cat $(OTEL_CLIENT_SECRETS_DIR)/$(OTEL_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(OTEL_SERVER_KEY): $$(cat $(OTEL_SERVER_SECRETS_DIR)/$(OTEL_SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(DNSX_SERVER_KEY): $$(cat $(DNSX_SERVER_SECRETS_DIR)/$(DNSX_SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(GSLB_SERVER_KEY): $$(cat $(GSLB_SERVER_SECRETS_DIR)/$(GSLB_SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(GSLB_CLIENT_KEY): $$(cat $(GSLB_CLIENT_SECRETS_DIR)/$(GSLB_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(GSLB_PROBE_AGENT_SERVER_KEY): $$(cat $(GSLB_PROBE_AGENT_SERVER_SECRETS_DIR)/$(GSLB_PROBE_AGENT_SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(GSLB_PROBE_AGENT_CLIENT_KEY): $$(cat $(GSLB_PROBE_AGENT_CLIENT_SECRETS_DIR)/$(GSLB_PROBE_AGENT_CLIENT_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(FQDN_KEY): $$(cat $(FQDN_SECRETS_DIR)/$(FQDN_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)
	@echo " $(VALIDATION_SERVER_KEY): $$(cat $(VALIDATION_SERVER_SECRETS_DIR)/$(VALIDATION_SERVER_KEY) | base64 -w 0)" >> $(SECRET_KEY_FILE)

.PHONY: create-secret-yamls
create-secret-yamls: create-cert-secrets-yaml create-key-secrets-yaml

## Install the secrets after creating .yaml files
.PHONY: install-secrets
install-secrets: uninstall-secrets gen-secrets create-secret-yamls
	kubectl apply -f $(SECRET_CERT_FILE) --namespace=$(CONTROLLER_NAMESPACE)
	kubectl apply -f $(SECRET_KEY_FILE) --namespace=$(CONTROLLER_NAMESPACE)

.PHONY: uninstall-secrets
uninstall-secrets:
	-kubectl delete secret --namespace=$(CONTROLLER_NAMESPACE) certs-secret
	-kubectl delete secret --namespace=$(CONTROLLER_NAMESPACE) keys-secret
