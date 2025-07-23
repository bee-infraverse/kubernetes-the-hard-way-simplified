#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

mkdir -p ~/kubernetes-the-hard-way
cd ~/kubernetes-the-hard-way

if [ ! -d downloads ]; then
  echo 'Creating downloads directory'
  mkdir -p downloads
else
  echo 'Using existing downloads directory'
fi

cat >downloads-${ARCH}.txt <<EOF
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kubectl
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kube-apiserver
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kube-controller-manager
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kube-scheduler
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kube-proxy
https://dl.k8s.io/${K8S_VERSION}/bin/linux/${ARCH}/kubelet
https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz
https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${ARCH}
https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS}.tgz
https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz
EOF

echo 'downloading files'

wget -q --show-progress \
  --https-only \
  --timestamping \
  -P downloads \
  -i downloads-${ARCH}.txt

echo 'Extracting downloaded files'

mkdir -p downloads/{client,cni-plugins,controller,worker}
tar -xvf downloads/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz \
  -C downloads/worker/
tar -xvf downloads/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz \
  --strip-components 1 \
  -C downloads/worker/
tar -xvf downloads/cni-plugins-linux-${ARCH}-${CNI_PLUGINS}.tgz \
  -C downloads/cni-plugins/
tar -xvf downloads/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz \
  -C downloads/ \
  --strip-components 1 \
  etcd-${ETCD_VERSION}-linux-${ARCH}/etcdctl \
  etcd-${ETCD_VERSION}-linux-${ARCH}/etcd
mv downloads/{etcdctl,kubectl} downloads/client/
mv downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
  downloads/controller/
mv downloads/{kubelet,kube-proxy} downloads/worker/
mv downloads/runc.${ARCH} downloads/worker/runc

rm -rf downloads/*gz downloads/cni-plugins/README.md downloads/cni-plugins/LICENSE
chmod +x downloads/{client,cni-plugins,controller,worker}/*

echo '✅ Kubernetes binaries downloaded and extracted successfully.'

if ! command -v helm &> /dev/null; then
  echo "Helm is not installed, proceeding with installation."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  helm version
  echo "✅ add helm completion 'helm' to bashrc. Source it again!"
  echo "source <(helm completion bash)" >>~/.bashrc
else
  echo "Helm is already installed, skipping installation."
fi

if ! command -v k9s &> /dev/null; then
  echo '✅ Install k9s.'
  curl -sS https://webinstall.dev/k9s | bash
fi

if alias k &>/dev/null; then
  echo "alias 'k' is defined"
else
  echo "✅ add alias 'k' and kubectl completion to bashrc. Source it again!"
  echo 'source <(kubectl completion bash)' >>~/.bashrc
  echo 'alias k=kubectl' >>~/.bashrc && echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
fi


