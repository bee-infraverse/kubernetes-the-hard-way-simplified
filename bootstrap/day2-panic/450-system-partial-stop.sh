#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

echo "stop kube-scheduler and kube-controller-manager at server"
ssh root@server <<EOF
  systemctl stop kube-scheduler
  systemctl stop kube-controller-manager
EOF

for host in node-0 node-1; do
echo "stop kubelet and kube-proxy at worker ${host}"

ssh root@${host} <<EOF
systemctl stop kubelet
systemctl stop containerd
systemctl stop kube-proxy
EOF

done