#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

wait_for_ssh() {
    local host="$1"
    local port="${2:-22}"
    local timeout="${3:-30}"
    local start_time=$(date +%s)

    echo "⏳ Waiting for SSH on $host:$port (timeout: $timeout seconds)..."

    while true; do
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "✅ SSH is available on $host:$port"
            return 0
        fi

        local now=$(date +%s)
        local elapsed=$(( now - start_time ))

        if (( elapsed >= timeout )); then
            echo "❌ Timeout reached ($timeout seconds). SSH not available on $host:$port"
            return 1
        fi

        sleep 2
    done
}

cd ~/kubernetes-the-hard-way

cat >machines.txt <<EOF
172.16.0.3 server server.local
172.16.0.4 node-0 node-0.local 10.200.0.0/24
172.16.0.5 node-1 node-1.local 10.200.1.0/24
EOF

while IFS=' ' read -r IP HOST FQDN SUBNET; do
    wait_for_ssh "$HOST" 22 30 || exit 1

    if ssh-keygen -F "$HOST" > /dev/null 2>&1; then
      echo "  -> $HOST already in known_hosts, skipping SSH config."
      continue
    fi
    ssh-keyscan "$HOST" >> ~/.ssh/known_hosts 2>/dev/null
    ssh laborant@$HOST "sudo /bin/sh -c 'echo \"PermitRootLogin yes\" > /etc/ssh/ssh_config.d/lab.conf'"
    ssh laborant@$HOST "sudo systemctl restart sshd" 2>/dev/null </dev/null
    {"
    echo ""
    grep flexbox ~/.ssh/authorized_keys
    } | ssh laborant@$HOST "sudo tee -a /root/.ssh/authorized_keys >/dev/null"
done < machines.txt

echo "✅ Root SSH access configured for all kubernetes cluster machines."
