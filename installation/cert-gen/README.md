# cert-gen (CertificateGenerator)
**This repository contains modifications in tls-gen lib for creation of multiple client certificates.**

- To generate secrets for api-server:

    `sh cert-gen/gen_cert.sh -s=api-server -a=f5-spk-cwc.default -n=<no of client certficates needed>`

- To generate secrets for rabbit-mq:

    `sh cert-gen/gen_cert.sh -s=rabbit -a=rabbitmq-server.default.svc.cluster.local -n=<no of client certficates needed>`

    Here providing -n value is optional with the default value as 0. 

- To generate secrets for CNF:

    `sh cert-gen/gen_cert.sh -s=cnf -a=f5-validation-svc.validate-webhook.svc`

- To use the repository to just create a single server and multiple client certificates signed by the same CA:

    `cd basic`

    ` make CN=<common-name> CLIENT_ALT_NAME=${CAN} SERVER_ALT_NAME=${SAN} CLIENT_CERTS=<no of client certficates needed>`

    Here CLIENT_CERTS value should be greater than 1.

<details><summary>Usage:

</summary>

CLIENT_CERTS=0, will generate only one client and server certificate.

</details>

<details><summary>Documentation : </summary>


Usage: [CertificateGenerator.md](https://gitswarm.f5net.com/f5ingress/spk-license/cert-gen/-/blob/sagnihotri/changes/basic/CertificateGenerator.md)

CN and SAN: [tls-gen.md](https://gitswarm.f5net.com/f5ingress/spk-license/cert-gen/-/blob/sagnihotri/changes/tls_gen/tls-gen.md)

</details>
