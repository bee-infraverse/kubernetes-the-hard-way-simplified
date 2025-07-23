#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

if [ ! -f  ~/kubernetes-the-hard-way/encryption-config.yaml ]; then
  mkdir -p ~/kubernetes-the-hard-way/configs && cd ~/kubernetes-the-hard-way/configs
  export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
  if ! command -v "envsubst" &> /dev/null ; then
    sudo apt install -y gettext
  fi
  echo "✅ Encryption config file created at ~/kubernetes-the-hard-way/encryption-config.yaml"
  envsubst < ${GITROOT}/bootstrap/encryption-config-template.yaml \
    > ~/kubernetes-the-hard-way/encryption-config.yaml

  echo "✅ Copying encryption config file to server"
  scp ~/kubernetes-the-hard-way/encryption-config.yaml root@server:~/
else
  echo "Encryption config file already exists, skipping generation."
fi
