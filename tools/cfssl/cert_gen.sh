#!/bin/bash
if [ -z "$KUBERNETES_APISERVER" ];then
	echo "Usage: export KUBERNETES_APISERVER=https://192.168.130.11:6443"
	echo "bash $0"
	exit 1
fi

export KUBECONFIG_PATH=files
export SSL_PATH=$KUBECONFIG_PATH/pki
export CSR_PATH=tools/cfssl
mkdir -p $SSL_PATH

# ------------certs-------------
cfssl gencert --initca=true $CSR_PATH/k8s-root-ca-csr.json | cfssljson --bare $SSL_PATH/k8s-root-ca
for TARGET in kubernetes admin kube-proxy
do
    cfssl gencert --ca $SSL_PATH/k8s-root-ca.pem --ca-key $SSL_PATH/k8s-root-ca-key.pem --config $CSR_PATH/k8s-gencert.json --profile kubernetes $CSR_PATH/$TARGET-csr.json | cfssljson --bare $SSL_PATH/$TARGET
done

# ------------kubeconfig-------------
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

cat > $KUBECONFIG_PATH/known_tokens.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

# bootstrapping kubeconfig
kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_PATH/k8s-root-ca.pem \
  --embed-certs=true \
  --server=$KUBERNETES_APISERVER \
  --kubeconfig=$KUBECONFIG_PATH/bootstrap.kubeconfig

kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=$KUBECONFIG_PATH/bootstrap.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=$KUBECONFIG_PATH/bootstrap.kubeconfig

kubectl config use-context default --kubeconfig=$KUBECONFIG_PATH/bootstrap.kubeconfig


# kube-proxy kubeconfig
kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_PATH/k8s-root-ca.pem \
  --embed-certs=true \
  --server=$KUBERNETES_APISERVER \
  --kubeconfig=$KUBECONFIG_PATH/kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=$SSL_PATH/kube-proxy.pem \
  --client-key=$SSL_PATH/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=$KUBECONFIG_PATH/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=$KUBECONFIG_PATH/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=$KUBECONFIG_PATH/kube-proxy.kubeconfig


# admin kubeconfig
kubectl config set-cluster kubernetes \
   --certificate-authority=$SSL_PATH/k8s-root-ca.pem\
   --embed-certs=true \
   --server=$KUBERNETES_APISERVER \
   --kubeconfig=$KUBECONFIG_PATH/kubeconfig

kubectl config set-credentials kubernetes-admin \
   --client-certificate=$SSL_PATH/admin.pem \
   --client-key=$SSL_PATH/admin-key.pem \
   --embed-certs=true \
   --kubeconfig=$KUBECONFIG_PATH/kubeconfig

kubectl config set-context kubernetes-admin@kubernetes \
   --cluster=kubernetes \
   --user=kubernetes-admin \
   --kubeconfig=$KUBECONFIG_PATH/kubeconfig

kubectl config use-context kubernetes-admin@kubernetes --kubeconfig=$KUBECONFIG_PATH/kubeconfig

# Audit
cat >> $KUBECONFIG_PATH/audit-policy.yaml <<EOF
# Log all requests at the Metadata level.
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:
- level: Metadata
EOF

