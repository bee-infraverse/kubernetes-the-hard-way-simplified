#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

helm upgrade --install coredns coredns/coredns \
  --namespace kube-system \
  --values ${GITROOT}/bootstrap/day2-panic/coredns/coredns-hosts-values.yaml \
  --reuse-values \
  --wait
