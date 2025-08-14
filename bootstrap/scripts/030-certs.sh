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

if [ ! -f ca.conf ]; then
  echo 'Generating CA configuration file...'
  envsubst < ${GITROOT}/bootstrap/ca-template.conf > ca.conf
else
  echo 'CA configuration file already exists, skipping generation.'
fi

mkdir -p ${CA_DIR}
mkdir -p ${CERTS_DIR} && cd ${CERTS_DIR}

echo 'Generating CA certificate and key'

# shellcheck disable=SC2016
if [ ! -f ${CA_DIR}/ca.crt ]; then
  echo 'Generating CA certificate and key...'
  openssl genrsa -out ${CA_DIR}/ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ${CA_DIR}/ca.key -days 3653 \
    -config ${HOME}/kubernetes-the-hard-way/ca.conf \
    -out ${CA_DIR}/ca.crt
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
        -config "${HOME}/kubernetes-the-hard-way/ca.conf" -section ${i} \
        -out "${i}.csr"
    openssl x509 -req -days 3653 -in "${i}.csr" \
        -copy_extensions copyall \
        -sha256 -CA "${CA_DIR}/ca.crt" \
        -CAkey "${CA_DIR}/ca.key" \
        -CAcreateserial \
        -out "${i}.crt"
    echo "✅ Generated ${i}.crt and ${i}.key"
  fi
done

echo '✅ Created all certificates and keys'

for host in node-0 node-1; do
  ssh root@${host} mkdir -p /var/lib/kubelet/
  scp ${CA_DIR}/ca.crt \
    root@${host}:/var/lib/kubelet/
  scp ${CERTS_DIR}/${host}.crt \
    root@${host}:/var/lib/kubelet/kubelet.crt
  scp ${CERTS_DIR}${host}.key \
    root@${host}:/var/lib/kubelet/kubelet.key
done

echo '✅ Copying certificates and keys to worker nodes'

scp \
  ${CA_DIR}/ca.key ${CA_DIR}/ca.crt \
  ${CERTS_DIR}/kube-api-server.key ${CERTS_DIR}/kube-api-server.crt \
  ${CERTS_DIR}/service-accounts.key ${CERTS_DIR}/service-accounts.crt \
  root@server:~/

echo '✅ Copy the appropriate certificates and private keys to the server machine'
