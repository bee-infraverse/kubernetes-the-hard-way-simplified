FROM debian:13-slim AS DOWNLOADER

ARG TARGET_OS=linux
ARG TARGET_ARCH=amd64

# renovate: datasource=github-tags depName=kubernetes/kubernetes
ARG K8S_VERSION=v1.34.0
# renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
ARG CRICTL_VERSION=v1.34.0
# renovate: datasource=github-releases depName=opencontainers/runc
ARG RUNC_VERSION=v1.3.1
# renovate: datasource=github-releases depName=containernetworking/plugins
ARG CNI_PLUGINS=v1.7.1
# renovate: datasource=github-releases depName=containerd/containerd
ARG CONTAINERD_VERSION=2.1.4
# renovate: datasource=github-releases depName=etcd-io/etcd
ARG ETCD_VERSION=v3.6.4
# renovate: datasource=github-releases depName=containerd/nerdctl
ARG NERDCTL_VERSION=2.1.4
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v3.18.6
# renovate: datasource=github-releases depName=derailed/k9s
ARG K9S_VERSION=v0.32.5

ENV TARGET_OS=${TARGET_OS} \
    TARGET_ARCH=${TARGET_ARCH} \ 
    K8S_VERSION=${K8S_VERSION} \
    CRICTL_VERSION=${CRICTL_VERSION} \
    RUNC_VERSION=${RUNC_VERSION} \
    CNI_PLUGINS=${CNI_PLUGINS} \
    CONTAINERD_VERSION=${CONTAINERD_VERSION} \
    ETCD_VERSION=${ETCD_VERSION} \
    NERDCTL_VERSION=${NERDCTL_VERSION} \
    HELM_VERSION=${HELM_VERSION} \
    K9S_VERSION=${K9S_VERSION}
RUN <<'EOT' bash
set -euxo pipefail

mkdir -p /kubernetes-the-hard-way/downloads
cd /kubernetes-the-hard-way

cat > downloads.txt <<EOF
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kubectl
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kube-apiserver
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kube-controller-manager
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kube-scheduler
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kube-proxy
https://dl.k8s.io/${K8S_VERSION}/bin/${TARGET_OS}/${TARGET_ARCH}/kubelet
https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz
https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${TARGET_ARCH}
https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS}/cni-plugins-${TARGET_OS}-${TARGET_ARCH}-${CNI_PLUGINS}.tgz
https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz
https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz
https://get.helm.sh/helm-${HELM_VERSION}-${TARGET_OS}_${TARGET_ARCH}.tar.gz
https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGET_ARCH}.tar.gz
EOF

while read -r url; do
  file="$(basename "$url")"
  wget -q --timestamping --https-only -O "$file" "$url"
done < "download.txt"

mkdir -p client cni-plugins controller worker

tar -xvf crictl-${CRICTL_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz \
  -C worker/
tar -xvf containerd-${CONTAINERD_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz \
  --strip-components 1 \
  -C worker/
tar -xvf cni-plugins-${TARGET_OS}-${TARGET_ARCH}-${CNI_PLUGINS}.tgz \
  -C cni-plugins/
tar -xvf etcd-${ETCD_VERSION}-${TARGET_OS}-${TARGET_ARCH}.tar.gz \
  --strip-components 1 \
  -C . \
  etcd-${ETCD_VERSION}-${TARGET_OS}-${TARGET_ARCH}/etcdutl \
  etcd-${ETCD_VERSION}-${TARGET_OS}-${TARGET_ARCH}/etcdctl \
  etcd-${ETCD_VERSION}-${TARGET_OS}-${TARGET_ARCH}/etcd

tar -xzf helm-${HELM_VERSION}-${TARGET_OS}_${TARGET_ARCH}.tar.gz ${TARGET_OS}-${TARGET_ARCH}/helm
tar -xzf ${K9S_VERSION}/k9s_Linux_${TARGET_ARCH}.tar.gz k9s

mv {etcdctl,etcdutl,kubectl} client/
mv {etcd,kube-apiserver,kube-controller-manager,kube-scheduler} controller/
mv {kubelet,kube-proxy} worker/
mv runc.${TARGET_ARCH} worker/runc
mv ${TARGET_OS}-${TARGET_ARCH}/helm client/helm
mv k9s client/k9s

rm -rf ./*gz cni-plugins/README.md cni-plugins/LICENSE ./helm/
chmod +x client/* cni-plugins/* controller/* worker/*

EOT

FROM debian:13.slim AS HELM_PACKAGES

# renovate: datasource=github-releases depName=coredns/coredns
ARG COREDNS_VERSION=1.43.2
# renovate: datasource=github-releases depName=kubernetes-sigs/metrics-server
ARG METRICS_SERVER_VERSION=3.13.0 

RUN <<'EOT' bash
set -euxo pipefail

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

mkdir -p /helm-charts
cd helm-charts

# coredns
helm repo add coredns https://coredns.github.io/helm
helm pull --untar coredns:coredns --version $COREDNS_VERSION

# metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm pull --untar metrics-server:metrics-server --version $METRICS_SERVER_VERSION

# local-path-provisioner
cd /tmp
git clone https://github.com/rancher/local-path-provisioner.git
mv local-path-provisioner/deploy/chart/local-path-provisioner helm-charts/local-path-provisioner
rm /tmp/local-path-provisioner
EOT

FROM scratch

ARG KTHW_VERSION
ARG VCS_REF
ARG BUILD_DATE

COPY --from=DOWNLOADER /kubernetes-the-hard-way /kubernetes-the-hard-way

LABEL org.opencontainers.image.title="Kubernetes the Hard Way" \
      org.opencontainers.image.description="Prepackaged Kubernetes the Hard Way - Binaries" \
      org.opencontainers.image.url="https://github.com/bee-infraverse/kubernetes-the-hard-way-simplified" \
      org.opencontainers.image.source="https://github.com/bee-infraverse/kubernetes-the-hard-way-simplified" \
      org.opencontainers.image.version="${KTHW_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="bee42 solutions gmbh" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.created="${BUILD_DATE}"