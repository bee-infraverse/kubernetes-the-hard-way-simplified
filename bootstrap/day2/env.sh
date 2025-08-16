#!/usr/bin/env bash

export ARCH=$(dpkg --print-architecture)
export K8S_VERSION=${K8S_VERSION:-v1.33.2} # renovate: datasource=github-releases depName=kubernetes/kubernetes
export CRICTL_VERSION=${CRICTL_VERSION:-v1.33.0} # renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
export RUNC_VERSION=${RUNC_VERSION:-v1.3.0} # renovate: datasource=github-releases depName=opencontainers/runc
export CNI_PLUGINS=${CNI_PLUGINS:-v1.7.1} # renovate: datasource=github-releases depName=containernetworking/plugins
export CONTAINERD_VERSION=${CONTAINERD_VERSION:-2.1.4} # renovate: datasource=github-releases depName=containerd/containerd
export ETCD_VERSION=${ETCD_VERSION:-v3.6.4} # renovate: datasource=github-releases depName=etcd-io/etcd
export NERDCTL_VERSION=${NERDCTL_VERSION:-2.1.3} # renovate: datasource=github-releases depName=containerd/nerdctl
export HELM_VERSION=${HELM_VERSION:-v3.18.5} # renovate: datasource=github-releases depName=helm/helm
export BUILDCTL_VERSION=${BUILDCTL_VERSION:-v0.23.2} # renovate: datasource=github-releases depName=moby/buildkit
export TRIVY_VERSION=${TRIVY_VERSION:-v0.65.0} # renovate: datasource=github-releases depName=aquasecurity/trivy
export CRANE_VERSION=${CRANE_VERSION:-v0.20.6} # renovate: datasource=github-releases depName=google/go-containerregistry
export GRANT_VERSION=${GRANT_VERSION:-v0.2.8} # renovate: datasource=github-releases depName=anchore/grant
export SYFT_VERSION=${SYFT_VERSION:-v1.31.0} # renovate: datasource=github-releases depName=anchore/syft
export GRYPE_VERSION=${GRYPE_VERSION:-v0.97.1} # renovate: datasource=github-releases depName=anchore/grype
export REGCTL_VERSION=${REGCTL_VERSION:-v0.9.0} # renovate: datasource=github-releases depName=regclient/regclient

export CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-cluster.local}
export COUNTRY="${COUNTRY:-DE}"
export CITY="${CITY:-Bochum}"
export STATE="${STATE:-NRW}"

export CA_DIR="${CA_DIR:-${HOME}/kubernetes-the-hard-way/certs}"
export CERTS_DIR="${CERTS_DIR:-${HOME}/kubernetes-the-hard-way/certs}"
export KUBE_CONFIGS_DIR="${KUBE_CONFIGS_DIR:-${HOME}/kubernetes-the-hard-way/kube-configs}"