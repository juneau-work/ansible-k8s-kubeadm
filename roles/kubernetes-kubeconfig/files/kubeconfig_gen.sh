#!/bin/bash
export APISERVER=$1
export SSL_PATH=/etc/kubernetes/pki
export KUBECONFIG_PATH=/etc/kubernetes/kubeconfig
export CLUSTER_NICK=kubernetes
export USER_NICK=kubelet
export CONTEXT=$USER_NICK@$CLUSTER_NICK

# Cluster
kubectl config set-cluster $CLUSTER_NICK \
    --server=$APISERVER \
    --certificate-authority=$SSL_PATH/ca.crt \
    --embed-certs=true \
    --kubeconfig=$KUBECONFIG_PATH
# User
kubectl config set-credentials $USER_NICK \
    --client-certificate=$SSL_PATH/server.crt \
    --client-key=$SSL_PATH/server.key \
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
