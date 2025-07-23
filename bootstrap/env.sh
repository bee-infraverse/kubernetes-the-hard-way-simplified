#!/usr/bin/env bash

export \
  ARCH=$(dpkg --print-architecture) \
  K8S_VERSION=${K8S_VERSION:-v1.33.2} \ # renovate: datasource=github-releases depName=kubernetes/kubernetes
  CRICTL_VERSION=${CRICTL_VERSION:-v1.33.0} \ # renovate: datasource=github-releases depName=kubernetes-sigs/cri-tools
  RUNC_VERSION=${RUNC_VERSION:-v1.3.0} \ # renovate: datasource=github-releases depName=opencontainers/runc
  CNI_PLUGINS=${CNI_PLUGINS:-v1.7.1} \ # renovate: datasource=github-releases depName=containernetworking/plugins
  CONTAINERD_VERSION=${CONTAINERD_VERSION:-2.1.3} \ # renovate: datasource=github-releases depName=containerd/containerd
  ETCD_VERSION=${ETCD_VERSION:-v3.6.1} \ # renovate: datasource=github-releases depName=etcd-io/etcd
  NERDCTL_VERSION=${NERDCTL_VERSION:-2.1.3} \ # renovate: datasource=github-releases depName=containerd/nerdctl
  HELM_VERSION=${HELM_VERSION:-v3.18.4} \ # renovate: datasource=github-releases depName=helm/helm
  CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-cluster.local} \
  COUNTRY="${COUNTRY:-DE}" \
  CITY="${CITY:-Bochum}" \
  STATE="${STATE:-NRW}"
