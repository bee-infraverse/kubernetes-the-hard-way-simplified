#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

mkdir -p ~/kubernetes-the-hard-way/kube-configs
cd ~/kubernetes-the-hard-way/kube-configs

echo 'Generating Kubernetes configuration files worker nodes'

for host in node-0 node-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=../certs/ca.crt \
    --embed-certs=true \
    --server=https://server.local:6443 \
    --kubeconfig=${host}.kubeconfig
  kubectl config set-credentials system:node:${host} \
    --client-certificate=../certs/${host}.crt \
    --client-key=../certs/${host}.key \
    --embed-certs=true \
    --kubeconfig=${host}.kubeconfig
  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${host} \
    --kubeconfig=${host}.kubeconfig
  kubectl config use-context default \
    --kubeconfig=${host}.kubeconfig
  echo "✅ Generating Kubernetes configuration files worker node ${host}"
done

echo '✅ Generate a kubeconfig file for the kube-proxy service'

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=../certs/ca.crt \
  --embed-certs=true \
  --server=https://server.local:6443 \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials system:kube-proxy \
  --client-certificate=../certs/kube-proxy.crt \
  --client-key=../certs/kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default \
  --kubeconfig=kube-proxy.kubeconfig

echo '✅ Generate a kubeconfig file for the kube-controller-manager service'

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=../certs/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=../certs/kube-controller-manager.crt \
  --client-key=../certs/kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig
kubectl config use-context default \
  --kubeconfig=kube-controller-manager.kubeconfig

echo '✅ Generate a kubeconfig file for the kube-scheduler service'

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=../certs/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=../certs/kube-scheduler.crt \
  --client-key=../certs/kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig
kubectl config use-context default \
  --kubeconfig=kube-scheduler.kubeconfig

echo '✅ Generate a kubeconfig file for the admin user'

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=../certs/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig
kubectl config set-credentials admin \
  --client-certificate=../certs/admin.crt \
  --client-key=../certs/admin.key \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig
kubectl config use-context default \
  --kubeconfig=admin.kubeconfig

echo '✅ Copy the kubelet and kube-proxy kubeconfig files to the node-0 and node-1 machines'

for host in node-0 node-1; do
  ssh root@${host} "mkdir -p /var/lib/kube-proxy /var/lib/kubelet"
  scp kube-proxy.kubeconfig \
    root@${host}:/var/lib/kube-proxy/kubeconfig \
  scp ${host}.kubeconfig \
    root@${host}:/var/lib/kubelet/kubeconfig
done

echo '✅ Copy the kube-controller-manager and kube-scheduler kubeconfig files to the server machine'

scp admin.kubeconfig \
  kube-controller-manager.kubeconfig \
  kube-scheduler.kubeconfig \
  root@server:~/

echo '✅ Copy the controlplane kubeconfig file to the local machine'