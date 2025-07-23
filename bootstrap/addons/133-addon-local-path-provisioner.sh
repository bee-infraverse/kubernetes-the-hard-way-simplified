#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

cd ~/kubernetes-the-hard-way

git clone https://github.com/rancher/local-path-provisioner.git
helm install local-path-storage local-path-provisioner/deploy/chart/local-path-provisioner \
  --namespace local-path-storage \
  --create-namespace \
  --set storageClass.defaultClass=true \
  --set nodePath="/opt/local-path-provisioner"

kubectl wait deployment/local-path-provisioner -n local-path-storage \
  --for condition=Available=True --timeout=30s

kubectl get pods -n local-path-storage -l app=local-path-provisioner
kubectl get storageclass | grep local-path

echo "✅ Local Path Provisioner installed successfully"

