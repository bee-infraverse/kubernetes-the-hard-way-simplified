#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

# Rotate certificates
cd ~/kubernetes-the-hard-way

# backup certs dir
mkdir -p backups/certs-$(date +%Y-%m-%d)
cp -r ${CERTS_DIR}/* backups/certs-$(date +%Y-%m-%d)/

# Create and transfer new certs
export CERTS_DIR="~/kubernetes-the-hard-way/certs-$(date +%Y-%m-%d)"
mkdir -p ${CERTS_DIR}
scripts/030-certs.sh

# Create front client and transfer
openssl genrsa -out "${CERTS_DIR}/front-proxy-client.key" 4096
openssl req -new -key "${CERTS_DIR}/front-proxy-client.key" -sha256 \
  -config "~/kubernetes-the-hard-wayfront-ca.conf" -section front-proxy-client \
  -out "${CERTS_DIR}/front-proxy-client.csr"

openssl x509 -req -days 90 -in "${CERTS_DIR}/front-proxy-client.csr" \
  -copy_extensions copyall \
  -sha256 -CA "${CA_DIR}/kubernetes-front-proxy-ca.crt" \
  -CAkey "${CA_DIR}/kubernetes-front-proxy-ca.key" \
  -CAcreateserial \
  -out "${CERTS_DIR}/front-proxy-client.crt"
scp \
  ${CA_DIR}/kubernetes-front-proxy-ca.key ${CA_DIR}/kubernetes-front-proxy-ca.crt \
  ${CERTS_DIR}/front-proxy-client.key ${CERTS_DIR}/front-proxy-client.crt \
  root@server:~/

# Create kubeconfigs
scripts/040-kubeconfigs.sh

# stop services
echo 'Stopping services on the control-plane machine'

ssh root@server <<'EOF'
systemctl stop kube-scheduler
systemctl stop kube-controller-manager
systemctl stop kube-apiserver
EOF

# transfer certs and kubeconfigs and start services
echo 'Transferring certificates and kubeconfigs and starting the control-plane services'
ssh root@server <<EOF
  mv ca.crt ca.key \
    kube-api-server.key kube-api-server.crt \   
    service-accounts.key service-accounts.crt \
    kubernetes-front-proxy-ca.key kubernetes-front-proxy-ca.crt \
    front-proxy-client.key front-proxy-client.crt \
    *.kubeconfig \
    /var/lib/kubernetes/
  systemctl daemon-reload
  systemctl start kube-apiserver
  systemctl start kube-scheduler
  systemctl start kube-controller-manager
EOF

# restart nodes
for host in node-0 node-1; do
echo "restarting kubelet and kube-proxy at worker ${host}"

ssh root@${host} <<EOF
systemctl daemon-reload
systemctl restart kubelet
systemctl restart kube-proxy
EOF

done
