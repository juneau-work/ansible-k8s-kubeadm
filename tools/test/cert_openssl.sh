#!/bin/bash
if [ -z "${KUBERNETES_APISERVER}" ];then
	echo "Usage: export KUBERNETES_APISERVER=https://192.168.130.11:443"
	echo "bash $0"
	exit 1
fi

CN=$(echo $KUBERNETES_APISERVER|grep -o '\d\+.\d\+.\d\+.\d\+')
CERT_DIR=files/pki
mkdir -p $CERT_DIR

echo $(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64 | tr -d "=+/" | dd bs=32 count=1 2>/dev/null),kube-admin,1 > $CERT_DIR/known_tokens.csv
echo PASS,kube-admin,1 > $CERT_DIR/basic_auth.csv

# i.ca
openssl genrsa -out $CERT_DIR/ca.key 2048
openssl req -x509 -new -nodes -key $CERT_DIR/ca.key -subj "/CN=$CN" -days 10000 -out $CERT_DIR/ca.crt

# ii.server
openssl genrsa -out $CERT_DIR/server.key 2048
cat >$CERT_DIR/csr.conf <<EOF
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
CN = $CN
    
[ req_ext ]
subjectAltName = @alt_names
    
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = $CN
IP.2 = 10.254.0.1
IP.3 = 10.96.0.1

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

openssl req -new -key $CERT_DIR/server.key -out $CERT_DIR/server.csr -config $CERT_DIR/csr.conf
openssl x509 -req -in $CERT_DIR/server.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/server.crt -days 10000 -extensions v3_ext -extfile $CERT_DIR/csr.conf
openssl x509 -noout -text -in $CERT_DIR/server.crt

# -----------------------
export KUBECONFIG_PATH=files/kubeconfig
export CLUSTER_NICK=kubernetes
export USER_NICK=kubelet
export CONTEXT=$USER_NICK@$CLUSTER_NICK

# Cluster
kubectl config set-cluster $CLUSTER_NICK \
    --server=$KUBERNETES_APISERVER \
    --certificate-authority=$CERT_DIR/ca.crt \
    --embed-certs=true \
    --kubeconfig=$KUBECONFIG_PATH
# User
kubectl config set-credentials $USER_NICK \
    --client-certificate=$CERT_DIR/server.crt \
    --client-key=$CERT_DIR/server.key \
    --embed-certs=true \
    --kubeconfig=$KUBECONFIG_PATH
# Context
kubectl config set-context $CONTEXT \
    --cluster=$CLUSTER_NICK \
    --user=$USER_NICK \
    --kubeconfig=$KUBECONFIG_PATH
# Switched to context
kubectl config use-context $CONTEXT \
    --kubeconfig=$KUBECONFIG_PATH
