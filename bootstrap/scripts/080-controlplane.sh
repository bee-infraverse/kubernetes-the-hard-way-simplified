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

echo 'Create system unit api server'

cat >kube-apiserver.service <<EOF
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
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo 'Create system unit controller manager'

cat >kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --bind-address=127.0.0.1 \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.crt \
  --cluster-signing-key-file=/var/lib/kubernetes/ca.key \
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
  --root-ca-file=/var/lib/kubernetes/ca.crt \
  --service-account-private-key-file=/var/lib/kubernetes/service-accounts.key \
  --service-cluster-ip-range=10.32.0.0/24 \
  --use-service-account-credentials=true \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo 'Create system unit scheduler'

cat >kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --bind-address=127.0.0.1 \
  --config=/etc/kubernetes/config/kube-scheduler.yaml \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

mkdir -p ~/kubernetes-the-hard-way/configs
cd ~/kubernetes-the-hard-way/configs

echo 'Creating kube-schedule config'

cat >kube-scheduler.yaml <<EOF
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

echo 'Creating kube-apiserver to kubelet RBAC'

cat >kube-apiserver-to-kubelet.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

echo '✅ Transfer all files to server machine'

cd ~/kubernetes-the-hard-way

scp \
  downloads/controller/kube-apiserver \
  downloads/controller/kube-controller-manager \
  downloads/controller/kube-scheduler \
  downloads/client/kubectl \
  units/kube-apiserver.service \
  units/kube-controller-manager.service \
  units/kube-scheduler.service \
  configs/kube-scheduler.yaml \
  configs/kube-apiserver-to-kubelet.yaml \
  root@server:~/

echo '✅ Move files to right dirs at server machine'

ssh -T root@server <<'EOF'
  mkdir -p /etc/kubernetes/config
  mv kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl \
    /usr/local/bin/
  mkdir -p /var/lib/kubernetes/
  mv ca.crt ca.key \
    kube-api-server.key kube-api-server.crt \
    service-accounts.key service-accounts.crt \
    encryption-config.yaml \
    /var/lib/kubernetes/
EOF

echo '✅ start controlplane services api-server, controller-manager, scheduler'

ssh -T root@server <<'EOF'
  mv kube-apiserver.service \
    /etc/systemd/system/kube-apiserver.service
  mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
  mv kube-controller-manager.service /etc/systemd/system/
  mv kube-scheduler.kubeconfig /var/lib/kubernetes/
  mv kube-scheduler.yaml /etc/kubernetes/config/
  mv kube-scheduler.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable kube-apiserver \
    kube-controller-manager kube-scheduler
  systemctl start kube-apiserver \
    kube-controller-manager kube-scheduler
EOF

ssh -T root@server <<'EOF'
  echo 'Waiting for kube-apiserver to start...'
  until systemctl is-active kube-apiserver; do
    sleep 1
  done
  echo 'kube-apiserver is running.'
  systemctl status kube-apiserver
  kubectl cluster-info \
    --kubeconfig admin.kubeconfig
EOF

ssh -T root@server <<'EOF'
  echo 'Waiting for kube-controller-manager to start...'
  until systemctl is-active kube-controller-manager; do
    sleep 1
  done
  echo 'kube-controller-manager is running.'
  systemctl status kube-controller-manager
EOF

ssh -T root@server <<'EOF'
  echo 'Waiting for kube-scheduler to start...'
  until systemctl is-active kube-scheduler; do
    sleep 1
  done
  echo 'kube-scheduler is running.'
  systemctl status kube-scheduler
EOF

ssh -T root@server <<'EOF'
  kubectl apply -f kube-apiserver-to-kubelet.yaml \
    --kubeconfig admin.kubeconfig
  echo 'kube-apiserver-to-kubelet ClusterRole and ClusterRoleBinding created.'
EOF

echo 'Testing API server connectivity'
curl --cacert ~/kubernetes-the-hard-way/certs/ca.crt \
  https://server.local:6443/version

echo '✅ Creating control plane components successfully'

if ! -f ~/.kube/config; then
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/home/laborant/kubernetes-the-hard-way/certs/ca.crt \
    --embed-certs=true \
    --server=https://server.local:6443
  kubectl config set-credentials admin \
    --client-certificate=/home/laborant/kubernetes-the-hard-way/certs/admin.crt \
    --client-key=/home/laborant/kubernetes-the-hard-way/certs/admin.key
  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin
  kubectl config use-context kubernetes-the-hard-way
  echo '✅ Creating admin config at jumpbox'
else
  echo 'admin config is already installed, skipping installation.'
fi
