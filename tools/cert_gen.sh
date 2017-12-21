#!/bin/bash
if [ -z "${MASTER_CLUSTER_IP}" ];then
	echo "Usage: export MASTER_CLUSTER_IP=192.168.130.100"
	echo "bash $0"
	exit 1
fi
mkdir -p roles/kubernetes-kubeconfig/files/pki
cd roles/kubernetes-kubeconfig/files/pki

# i.ca
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=${MASTER_CLUSTER_IP}" -days 10000 -out ca.crt

# ii.apiserver
openssl genrsa -out apiserver.key 2048
cat >csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
    
[ dn ]
C = CN
ST = Shanghai
L = Shanghai
O = Wanda., Ltd
OU = wandayun
    
[ req_ext ]
subjectAltName = @alt_names
    
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${MASTER_CLUSTER_IP}
IP.2 = 10.254.0.1
IP.3 = 10.96.0.10

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

openssl req -new -key apiserver.key -out apiserver.csr -config csr.conf
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key \
-CAcreateserial -out apiserver.crt -days 10000 \
-extensions v3_ext -extfile csr.conf
openssl x509 -noout -text -in apiserver.crt
