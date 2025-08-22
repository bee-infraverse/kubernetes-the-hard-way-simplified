#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

cd ~/kubernetes-the-hard-way/configs
cat >10-dns.conf <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
clusterDNS:
  - 10.0.0.10
clusterDomain: ${CLUSTER_DOMAIN}
EOF
cat >20-tuning.conf <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
maxPods: 110
EOF

cd ~/kubernetes-the-hard-way
for host in node-0 node-1; do
  echo "✅ preparing worker node ${host} for use coreDNS"
  scp configs/10-dns.conf configs/20-tuning.conf \
    root@${host}:/var/lib/kubelet/config.d/
  ssh root@${host} "systemctl restart kubelet"
done

if ! helm repo list | grep -q '^coredns'; then
  helm repo add coredns https://coredns.github.io/helm
else
  echo "Helm repo 'coredns' already exists"
fi

helm repo update

helm upgrade --install coredns coredns/coredns \
  --namespace kube-system \
  --set isClusterService=true \
  --set service.clusterIP="10.0.0.10" \
  --set service.name="kube-dns" \
  --set replicaCount=2 \
  --set k8sAppLabelOverride="kube-dns" \
  --wait

#kubectl wait --for=condition=available --timeout=60s deployment/coredns -n kube-system
kubectl get pods -n kube-system -l k8s- dapp=kube-dns

echo "✅ CoreDNS is now running. You can check its status with:"
