#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

for node in node-0 node-1; do
  echo "Preparing ${node} for Kubernetes worker node"
  ssh root@${node} <<EOF
    swapon --show
    swapoff -a
    mkdir -p \
    /etc/cni/net.d \
    /opt/cni/bin \
    /var/lib/kubelet \
    /var/lib/kubelet/config.d \
    /var/lib/kube-proxy \
    /var/lib/kubernetes \
    /var/run/kubernetes
    mv crictl ctr kube-proxy kubelet runc \
    /usr/local/bin/
    mv containerd containerd-shim-runc-v2 containerd-stress /bin/
    mv cni-plugins/* /opt/cni/bin/
    mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
    modprobe br-netfilter
    echo "br-netfilter" >> /etc/modules-load.d/modules.conf
    echo "net.bridge.bridge-nf-call-iptables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
    echo "net.bridge.bridge-nf-call-ip6tables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
    sysctl -p /etc/sysctl.d/kubernetes.conf
    echo "Creating containerd and kubelet configuration files at ${node}"
    mkdir -p /etc/containerd/
    mv containerd-config.toml /etc/containerd/config.toml
    mv containerd.service /etc/systemd/system/
    mv kubelet-config.yaml /var/lib/kubelet/
    mv kubelet.service /etc/systemd/system/
    echo "Configure the Kubernetes Proxy at ${node}"
    mv kube-proxy-config.yaml /var/lib/kube-proxy/
    mv kube-proxy.service /etc/systemd/system/
    echo "Starting containerd, kubelet and kube-proxy services at node ${node}"
    systemctl daemon-reload
    systemctl enable containerd kubelet
    systemctl start containerd kubelet
    systemctl enable kube-proxy
    systemctl start kube-proxy
EOF
done

echo "Waiting for kubelet and kube-proxy to start on worker nodes"
for node in node-0 node-1; do
    ssh root@${node} <<EOF
        echo "Waiting for ${node} to start..."
        until systemctl is-active kubelet && systemctl is-active containerd && systemctl is-active kube-proxy; do
            sleep 1
        done
        echo "kubelet is running at ${node}."
EOF
done

echo "Checking the status of worker nodes via api-server"
ssh root@server \
  "kubectl get nodes \
  --kubeconfig admin.kubeconfig"

