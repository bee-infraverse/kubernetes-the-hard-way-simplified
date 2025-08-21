#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/hack/buildkitd/env.sh

mkdir -p ~/kubernetes-the-hard-way
cd ~/kubernetes-the-hard-way

if [ ! -d downloads ]; then
  echo 'Creating downloads directory'
  mkdir -p downloads
else
  echo 'Using existing downloads directory'
fi

DOWNLOAD_LIST="tools-${ARCH}.txt"
TRIVY_ARCH=$(get_trivy_arch)
if [[ "$ARCH" == "amd64" ]]; then
    ARCH_DL="x86_64"
fi

cat >"${DOWNLOAD_LIST}" <<EOF
https://github.com/moby/buildkit/releases/download/${BUILDCTL_VERSION}/buildkit-${BUILDCTL_VERSION}.linux-${ARCH}.tar.gz
https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-${TRIVY_ARCH}.tar.gz
https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${ARCH_DL}.tar.gz
https://github.com/anchore/grant/releases/download/${GRANT_VERSION}/grant_${GRANT_VERSION#v}_linux_${ARCH}.tar.gz
https://github.com/anchore/syft/releases/download/${SYFT_VERSION}/syft_${SYFT_VERSION#v}_linux_${ARCH}.tar.gz
https://github.com/anchore/grype/releases/download/${GRYPE_VERSION}/grype_${GRYPE_VERSION#v}_linux_${ARCH}.tar.gz
https://github.com/regclient/regclient/releases/download/${REGCTL_VERSION}/regctl-linux-${ARCH}
EOF

echo 'downloading files'

echo "[INFO] Checking files and downloading missing ones..."
while read -r url; do
    file="downloads/$(basename "$url")"
    if [[ -f "$file" ]]; then
        echo "[SKIP] $file already exists"
    else
        echo "[GET]  $url"
        wget -q --show-progress --timestamping --https-only -O "$file" "$url"
    fi
done < "${DOWNLOAD_LIST}"

if [ $? -ne 0 ]; then
  echo "Error downloading files. Please check your internet connection or the URLs."
  exit 1
fi
echo '✅ download files successfully'

echo 'Extracting downloaded files'

mkdir -p downloads/jumpbox/
tar -xvf downloads/buildkit-${BUILDCTL_VERSION}.linux-${ARCH}.tar.gz \
  -C downloads/jumpbox/ \
  --strip-components 1 \
   bin/buildctl
tar -xvf downloads/trivy_${TRIVY_VERSION#v}_Linux-${TRIVY_ARCH}.tar.gz \
  -C downloads/jumpbox/ \
   trivy
tar -xvf downloads/go-containerregistry_Linux_${ARCH_DL}.tar.gz \
  -C downloads/jumpbox/ \
  crane
tar -xvf downloads/grant_${GRANT_VERSION#v}_linux_${ARCH}.tar.gz \
  -C downloads/jumpbox/ \
  grant
tar -xvf downloads/syft_${SYFT_VERSION#v}_linux_${ARCH}.tar.gz \
  -C downloads/jumpbox/ \
  syft
tar -xvf downloads/grype_${GRYPE_VERSION#v}_linux_${ARCH}.tar.gz \
  -C downloads/jumpbox/ \
  grype
mv downloads/regctl-linux-${ARCH} downloads/jumpbox/regctl

chown +x downloads/jumpbox/*
sudo chown root:root downloads/jumpbox/*
sudo cp downloads/jumpbox/* /usr/local/bin/

echo '✅ Extracted build tools successfully'
echo 'Cleaning up downloaded files...'
rm -rf downloads/*.tar.gz
