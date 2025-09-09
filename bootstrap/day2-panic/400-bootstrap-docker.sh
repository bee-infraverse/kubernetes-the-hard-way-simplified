#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o ~/get-docker.sh
    # review get-docker.sh
    sudo sh ~/get-docker.sh
    sudo systemctl start docker
    sudo usermod -aG docker ${USER}
    newgrp docker

    echo "✅ jumpbox docker installation finished!"
else
    echo "docker available"
fi

