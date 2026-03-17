A **common name (CN)** represents the server name protected by the SSL certificate. It can only contain up to one entry: either a wildcard or non-wildcard name and hence it’s not possible to specify a list of names covered by an SSL certificate in the common name field.

The **Subject Alternative Name/Subject Alternate Name (SAN)** was introduced to solve this limitation. It is an extension to the X.509 specification that allows issuance of multi-name SSL certificates.
The use of the SAN extension is standard practice for SSL certificates, and it’s on its way to replacing the use of the common name.

GO 1.15 and above expects SAN to contain the URL used to access the server and deprecated support for Common Name fields in certificates, 
The tls-gen library generates certificates with SAN. It can create one client, server and a ca certificate per make command. 
This library was modified in such a way that using one make command, multiple client certificates could be generated signed by the same CA. 
