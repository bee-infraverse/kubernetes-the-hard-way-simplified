#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

cd ~/kubernetes-the-hard-way

cat >machines.txt <<EOF
172.16.0.3 server server.local
172.16.0.4 node-0 node-0.local 10.200.0.0/24
172.16.0.5 node-1 node-1.local 10.200.1.0/24
EOF

while IFS=' ' read -r IP HOST FQDN SUBNET; do
    if ssh-keygen -F "$HOST" > /dev/null 2>&1; then
      echo "  -> $HOST already in known_hosts, skipping SSH config."
      continue
    fi
    ssh-keyscan "$HOST" >> ~/.ssh/known_hosts 2>/dev/null
    ssh laborant@$HOST "sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config" </dev/null
    ssh laborant@$HOST "sudo systemctl restart sshd" 2>/dev/null </dev/null
    {
    echo ""
    grep flexbox ~/.ssh/authorized_keys
    } | ssh laborant@$HOST "sudo tee -a /root/.ssh/authorized_keys >/dev/null"
done < machines.txt

echo "✅ Root SSH access configured for all kubernetes cluster machines."
