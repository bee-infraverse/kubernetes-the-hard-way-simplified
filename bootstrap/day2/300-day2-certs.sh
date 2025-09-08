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

if [ ! -f ~/kubernetes-the-hard-way/etcd-ca.conf ]; then
  envsubst < ${GITROOT}/bootstrap/etcd-ca-template.conf > ~/kubernetes-the-hard-way/etcd-ca.conf
else
  echo 'etcd-ca.conf already exists, skipping generation.'
fi

mkdir -p ${CA_DIR}
mkdir -p ${CERTS_DIR} && cd ${CERTS_DIR}

echo 'Generating ETCD CA certificate and key'

# shellcheck disable=SC2016
if [ ! -f ${CA_DIR}/etcd-ca.crt ]; then
  echo 'Generating ETCD CA certificate and key...'
  openssl genrsa -out ${CA_DIR}/etcd-ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ${CA_DIR}/etcd-ca.key -days 3653 \
    -config ~/kubernetes-the-hard-way/etcd-ca.conf \
    -out ${CA_DIR}/etcd-ca.crt
else
  echo 'ETCD CA certificate already exists, skipping generation.'
fi

certs=(
  "etcd-client" "etcd-apiserver-client"
  "etcd-server" "etcd-peer"
)

for i in ${certs[*]}; do
  if [ ! -f ${i}.crt ]; then
    echo "Generated ${i}.crt and ${i}.key"
    openssl genrsa -out "${i}.key" 4096
    openssl req -new -key "${i}.key" -sha256 \
        -config "~/kubernetes-the-hard-way/etcd-ca.conf" -section ${i} \
        -out "${i}.csr"
    openssl x509 -req -days 90 -in "${i}.csr" \
        -copy_extensions copyall \
        -sha256 -CA "${CA_DIR}/etcd-ca.crt" \
        -CAkey "${CA_DIR}/etcd-ca.key" \
        -CAcreateserial \
        -out "${i}.crt"
    echo "✅ Generated ${i}.crt and ${i}.key"
  fi
done

echo '✅ Created all ETCD certificates and keys'

scp \
  ${CA_DIR}/etcd-ca.key ${CA_DIR}/etcd-ca.crt \
  root@server:~/

for i in ${certs[*]}; do
  scp \
    ${i}.key ${i}.crt \
    root@server:~/
done

ssh -T root@server <<'EOF'
  mv etcd-ca.crt etcd-ca.key \
    etcd-client.crt etcd-client.key \
    etcd-server.crt etcd-server.key \
    etcd-peer.crt etcd-peer.key \
    /etc/etcd/
  mv etcd-apiserver-client.crt etcd-apiserver-client.key \
    /var/lib/kubernetes
  cp /etc/etcd/etcd-ca.crt /etc/etcd/etcd-ca.key \
    /var/lib/kubernetes
  echo '✅ Etcd certs deployed!'
EOF

echo '✅ Copy the appropriate certificates and private keys to the server machine'

cd ~/kubernetes-the-hard-way
if [ ! -d units ]; then
  mkdir units
fi
if [ ! -f units/etcd-certs.service ]; then
  echo 'Creating etcd-certs service file'
  cat >units/etcd-certs.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name controller \
  --initial-advertise-peer-urls https://127.0.0.1:2380 \
  --listen-peer-urls https://127.0.0.1:2380 \
  --listen-client-urls https://127.0.0.1:2379 \
  --advertise-client-urls https://127.0.0.1:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster controller=https://127.0.0.1:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd \
  --cert-file=/etc/etcd/etcd-server.crt \
  --key-file=/etc/etcd/etcd-server.key \
  --client-cert-auth=true \
  --trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --peer-cert-file=/etc/etcd/etcd-peer.crt \
  --peer-key-file=/etc/etcd/etcd-peer.key \
  --peer-client-cert-auth=true \
  --peer-trusted-ca-file=/etc/etcd/etcd-ca.crt
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

else
  echo 'etcd-certs.service already exists, skipping creation.'
fi

echo 'Copying etcd-certs service file to the server machine'

scp \
  units/etcd-certs.service \
  root@server:/etc/systemd/system/etcd.service

ssh root@server "systemctl stop kube-apiserver"
echo '✅ stop  apiserver service!'

ssh root@server "systemctl daemon-reload && systemctl restart etcd"
echo '✅ start etcd service restart'

echo '✅ create api-server with etcd client systemd unit file'
cat >units/kube-apiserver-etcd.service <<'EOF'
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
  --etcd-servers=https://127.0.0.1:2379 \
  --etcd-cafile=/var/lib/kubernetes/etcd-ca.crt \
  --etcd-certfile=/var/lib/kubernetes/etcd-apiserver-client.crt \
  --etcd-keyfile=/var/lib/kubernetes/etcd-apiserver-client.key \
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

echo '✅ transfer apiserver system unit file'
scp \
  units/kube-apiserver-etcd.service \
  root@server:/etc/systemd/system/kube-apiserver.service
ssh root@server "systemctl daemon-reload && systemctl start kube-apiserver"

echo '✅ start apiserver service started again'

ssh -T root@server <<'EOF'
  echo 'Waiting for kube-apiserver to start...'
  until systemctl is-active kube-apiserver; do
    sleep 1
  done
  echo 'kube-apiserver is running.'
EOF
