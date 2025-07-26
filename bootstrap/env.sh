#!/usr/bin/env bash

export ARCH=$(dpkg --print-architecture)
export K8S_VERSION=${K8S_VERSION:-v1.33.2} # renovate: datasource=github-releases depName=kubernetes/kubernetes
export CRICTL_VERSION=${CRICTL_VERSION:-v1.33.0} # renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
export RUNC_VERSION=${RUNC_VERSION:-v1.3.0} # renovate: datasource=github-releases depName=opencontainers/runc
export CNI_PLUGINS=${CNI_PLUGINS:-v1.7.1} # renovate: datasource=github-releases depName=containernetworking/plugins
export CONTAINERD_VERSION=${CONTAINERD_VERSION:-2.1.3} # renovate: datasource=github-releases depName=containerd/containerd
export ETCD_VERSION=${ETCD_VERSION:-v3.6.4} # renovate: datasource=github-releases depName=etcd-io/etcd
export NERDCTL_VERSION=${NERDCTL_VERSION:-2.1.3} # renovate: datasource=github-releases depName=containerd/nerdctl
export HELM_VERSION=${HELM_VERSION:-v3.18.4} # renovate: datasource=github-releases depName=helm/helm
export CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-cluster.local}
export COUNTRY="${COUNTRY:-DE}"
export CITY="${CITY:-Bochum}"
export STATE="${STATE:-NRW}"
