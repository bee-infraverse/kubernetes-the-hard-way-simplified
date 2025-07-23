#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

cd ~/kubernetes-the-hard-way
envsubst < ${GITROOT}/bootstrap/front-ca-template.conf > front-ca.conf

echo 'Generate the certs with openssl'

cd ~/kubernetes-the-hard-way/certs
openssl genrsa -out kubernetes-front-proxy-ca.key 4096
openssl req -x509 -new -sha512 -noenc \
  -key kubernetes-front-proxy-ca.key -days 3653 \
  -config ../front-ca.conf \
  -out kubernetes-front-proxy-ca.crt
openssl genrsa -out "front-proxy-client.key" 4096
openssl req -new -key "front-proxy-client.key" -sha256 \
  -config "../front-ca.conf" -section front-proxy-client \
  -out "front-proxy-client.csr"
openssl x509 -req -days 3653 -in "front-proxy-client.csr" \
  -copy_extensions copyall \
  -sha256 -CA "kubernetes-front-proxy-ca.crt" \
  -CAkey "kubernetes-front-proxy-ca.key" \
  -CAcreateserial \
  -out "front-proxy-client.crt"

cd ~/kubernetes-the-hard-way/units
cat >kube-apiserver-aggregator.service <<'EOF'
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --allow-privileged=true \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=/var/lib/kubernetes/ca.crt \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-servers=http://127.0.0.1:2379 \
  --event-ttl=1h \
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.crt \
  --kubelet-client-certificate=/var/lib/kubernetes/kube-api-server.crt \
  --kubelet-client-key=/var/lib/kubernetes/kube-api-server.key \
  --runtime-config='api/all=true' \
  --service-account-key-file=/var/lib/kubernetes/service-accounts.crt \
  --service-account-signing-key-file=/var/lib/kubernetes/service-accounts.key \
  --service-account-issuer=https://server.local:6443 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kube-api-server.crt \
  --tls-private-key-file=/var/lib/kubernetes/kube-api-server.key \
  --proxy-client-cert-file=/var/lib/kubernetes/front-proxy-client.crt \
  --proxy-client-key-file=/var/lib/kubernetes/front-proxy-client.key \
  --requestheader-allowed-names=front-proxy-client \
  --requestheader-client-ca-file=/var/lib/kubernetes/kubernetes-front-proxy-ca.crt \
  --requestheader-extra-headers-prefix=X-Remote-Extra- \
  --requestheader-group-headers=X-Remote-Group \
  --requestheader-username-headers=X-Remote-User \
  --enable-aggregator-routing=true \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

scp \
  certs/kubernetes-front-proxy-ca.key certs/kubernetes-front-proxy-ca.crt \
  certs/front-proxy-client.key certs/front-proxy-client.crt \
  root@server:/var/lib/kubernetes
scp \
  units/kube-apiserver-aggregator.service \
  root@server:/etc/systemd/system/kube-apiserver.service
ssh root@server "systemctl daemon-reload && systemctl restart kube-apiserver"

echo "Deploy the Metrics Server"

if ! helm repo list | grep -q '^metrics-server'; then
  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
else
  echo "✅ Helm repo 'metrics-server' already exists"
fi
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args='{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}'

echo 'Waiting for Metrics Server to start...'
kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system

kubectl top nodes
kubectl top pods -A
kubectl get apiservices v1beta1.metrics.k8s.io -o yaml

echo 'Metrics Server is running.'
