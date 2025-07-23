#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

cd ~/kubernetes-the-hard-way

SERVER_IP=$(grep server machines.txt | cut -d " " -f 1)
NODE_0_IP=$(grep node-0 machines.txt | cut -d " " -f 1)
NODE_0_SUBNET=$(grep node-0 machines.txt | cut -d " " -f 4)
NODE_1_IP=$(grep node-1 machines.txt | cut -d " " -f 1)
NODE_1_SUBNET=$(grep node-1 machines.txt | cut -d " " -f 4)

ssh -T root@server <<EOF
  ip route show ${NODE_0_SUBNET} | grep -q "via ${NODE_0_IP}" || ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
EOF
ssh -T root@server <<EOF
  ip route show ${NODE_1_SUBNET} | grep -q "via ${NODE_1_IP}" || ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF

ssh -T root@node-0 <<EOF
  ip route show ${NODE_1_SUBNET} | grep -q "via ${NODE_1_IP}" || ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF
ssh -T root@node-1 <<EOF
  ip route show ${NODE_0_SUBNET} | grep -q "via ${NODE_0_IP}" || ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
EOF
