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

DOWNLOAD_LIST="downloads-${ARCH}.txt"

cat >"${DOWNLOAD_LIST}" <<EOF
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

echo "[INFO] Checking files and downloading missing ones..."
while read -r url; do
    file="downloads/$(basename "$url")"
    if [[ -f "$file" ]]; then
        echo "[SKIP] $file already exists"
    else
        echo "[GET]  $url"
        wget -q --show-progress --timestamping --https-only -O "$file" "$url"
    fi
done < "${DOWNLOAD_LIST}"

if [ $? -ne 0 ]; then
  echo "Error downloading files. Please check your internet connection or the URLs."
  exit 1
fi

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
  etcd-${ETCD_VERSION}-linux-${ARCH}/etcdutl \
  etcd-${ETCD_VERSION}-linux-${ARCH}/etcdctl \
  etcd-${ETCD_VERSION}-linux-${ARCH}/etcd
mv downloads/{etcdctl,etcdutl,kubectl} downloads/client/
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

if ! command -v kubectl &> /dev/null; then
  echo '✅ Install kubectl.'
  sudo cp downloads/client/kubectl /usr/local/bin/
  sudo chown root:root /usr/local/bin/kubectl
else
  echo 'kubectl is already installed, skipping installation.'
fi

if alias k &>/dev/null; then
  echo "alias 'k' is defined"
else
  echo "✅ add alias 'k' and kubectl completion to bashrc. Source it again!"
  echo 'source <(kubectl completion bash)' >>~/.bashrc
  echo 'alias k=kubectl' >>~/.bashrc && echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
fi

if ! kubectl krew list &>/dev/null; then
  (
    set -x; cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxvf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
  )
  echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >>~/.bashrc
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  PACKAGES="ns ctx images node-shell stern neat ktop explore"
  kubectl krew install $PACKAGES
  echo '✅ krew package $PACKAGES are installed.'
else
  echo 'krew is already installed, skipping installation.'
fi

if ! -f "/usr/local/opt/kube-ps1/share/kube-ps1.sh" ; then
  curl -s https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh >./kube-ps1.sh
  
  sudo mkdir -p /usr/local/opt/kube-ps1/share
  sudo cp kube-ps1.sh /usr/local/opt/kube-ps1/share
  sudo chmod +x /usr/local/opt/kube-ps1/share/kube-ps1.sh
  
  echo "source /usr/local/opt/kube-ps1/share/kube-ps1.sh" >>~/.bashrc
  echo "PS1='\$(kube_ps1)'\$PS1\\\\n" >>~/.bashrc
  echo '✅ kube-ps1.sh is installed.'
else
  echo 'kube-ps1.sh is already installed, skipping installation.'
fi