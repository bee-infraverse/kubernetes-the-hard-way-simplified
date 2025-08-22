#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

YOUR_GIT_HOST=jumpbox.local

if [ ! -f ~/.ssh/id_cnbc-sync-rsa ]; then
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_cnbc-sync-rsa
  chmod 600 ~/.ssh/authorized_keys
  echo "" >>~/.ssh/authorized_keys
  cat ~/.ssh/id_cnbc-sync-rsa.pub >>~/.ssh/authorized_keys
  chmod 400 ~/.ssh/authorized_keys
  ssh-keyscan $YOUR_GIT_HOST >>~/.ssh/known_hosts
  echo "SSH key '~/.ssh/id_cnbc-sync-rsa' created!"
else
  echo "SSH key '~/.ssh/id_cnbc-sync-rsa' already exists, skipping."
fi

if ! kubectl get namespace content-site >/dev/null 2>&1; then
  kubectl create namespace content-site    
else
  echo "Namespace 'content-site' already exists, skipping."
fi

if ! kubectl get secret git-creds -n content-site >/dev/null 2>&1; then
  ssh-keyscan $YOUR_GIT_HOST >/tmp/known_hosts
  kubectl create secret generic git-creds \
    -n content-site \
    --from-file=ssh=$HOME/.ssh/id_cnbc-sync-rsa \
    --from-file=known_hosts=/tmp/known_hosts
else
  echo "Secret 'git-creds' already exists, skipping."
fi
echo "✅ local ssh key creation finished!"

