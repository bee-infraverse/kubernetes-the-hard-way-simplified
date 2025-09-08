#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

mkdir -p ~/kubernetes-the-hard-way/units
cd ~/kubernetes-the-hard-way/units

cat >etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name controller \
  --initial-advertise-peer-urls http://127.0.0.1:2380 \
  --listen-peer-urls http://127.0.0.1:2380 \
  --listen-client-urls http://127.0.0.1:2379 \
  --advertise-client-urls http://127.0.0.1:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster controller=http://127.0.0.1:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cd ~/kubernetes-the-hard-way

echo 'Copying etcd binaries and service file to the server machine'

scp \
  downloads/controller/etcd \
  downloads/client/etcdctl \
  downloads/client/etcdutl \
  units/etcd.service \
  root@server:~/

echo 'Setting up etcd on the server machine'

ssh -T root@server <<'EOF'
  mv etcd etcdctl etcdutl /usr/local/bin/
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/
  mv etcd.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
EOF
echo 'Waiting for etcd to start...'

ssh -T root@server <<'EOF'
  echo 'Waiting for etcd to start...'
  until systemctl is-active etcd; do
    sleep 1
  done
  echo 'etcd is running.'
  etcdctl --endpoints=http://127.0.0.1:2379 member list
EOF

echo '✅ etcd service is set up and running on the server machine'