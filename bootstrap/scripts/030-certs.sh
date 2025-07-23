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

envsubst < ${GITROOT}/bootstrap/ca-template.conf > ca.conf

mkdir -p ~/kubernetes-the-hard-way/certs && cd ~/kubernetes-the-hard-way/certs

echo 'Generating CA certificate and key'

# shellcheck disable=SC2016
if [ ! -f ca.crt ]; then
  echo 'Generating CA certificate and key...'
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ca.key -days 3653 \
    -config ../ca.conf \
    -out ca.crt
else
  echo 'CA certificate already exists, skipping generation.'
fi

certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  if [ ! -f ${i}.crt ]; then
    echo "Generated ${i}.crt and ${i}.key"
    openssl genrsa -out "${i}.key" 4096
    openssl req -new -key "${i}.key" -sha256 \
        -config "../ca.conf" -section ${i} \
        -out "${i}.csr"
    openssl x509 -req -days 3653 -in "${i}.csr" \
        -copy_extensions copyall \
        -sha256 -CA "ca.crt" \
        -CAkey "ca.key" \
        -CAcreateserial \
        -out "${i}.crt"
    echo "✅ Generated ${i}.crt and ${i}.key"
  fi
done

echo '✅ Created all certificates and keys'

for host in node-0 node-1; do
  ssh root@${host} mkdir -p /var/lib/kubelet/
  scp ca.crt root@${host}:/var/lib/kubelet/
  scp ${host}.crt \
    root@${host}:/var/lib/kubelet/kubelet.crt
  scp ${host}.key \
    root@${host}:/var/lib/kubelet/kubelet.key
done

echo '✅ Copying certificates and keys to worker nodes'


scp \
  ca.key ca.crt \
  kube-api-server.key kube-api-server.crt \
  service-accounts.key service-accounts.crt \
  root@server:~/

echo '✅ Copy the appropriate certificates and private keys to the server machine'
