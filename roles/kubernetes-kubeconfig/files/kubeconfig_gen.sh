#!/bin/bash
export APISERVER=$1
export SSL_PATH=/etc/kubernetes/pki
export CLUSTER_NICK=kubernetes

# kubelet.conf
export KUBECONFIG_PATH=/etc/kubernetes/kubelet.conf
export USER_NICK=system:node:$HOSTNAME
export CONTEXT=$USER_NICK@$CLUSTER_NICK

kubeconfig_gen(){
# Cluster
kubectl config set-cluster $CLUSTER_NICK \
    --server=$APISERVER \
    --certificate-authority=$SSL_PATH/ca.crt \
    --embed-certs=true \
    --kubeconfig=$KUBECONFIG_PATH
# User
kubectl config set-credentials $USER_NICK \
    --client-certificate=$SSL_PATH/apiserver.crt \
    --client-key=$SSL_PATH/apiserver.key \
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
}
kubeconfig_gen
    
# controller-manager.conf
export KUBECONFIG_PATH=/etc/kubernetes/controller-manager.conf
export USER_NICK=system:kube-controller-manager
export CONTEXT=$USER_NICK@$CLUSTER_NICK
kubeconfig_gen

# scheduler.conf
export KUBECONFIG_PATH=/etc/kubernetes/scheduler.conf
export USER_NICK=system:kube-scheduler
export CONTEXT=$USER_NICK@$CLUSTER_NICK
kubeconfig_gen

# admin.conf
export KUBECONFIG_PATH=/etc/kubernetes/admin.conf
export USER_NICK=kubernetes-admin
export CONTEXT=$USER_NICK@$CLUSTER_NICK
kubeconfig_gen
