#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

if [ ! -f ${GITROOT}/bootstrap/day2-panic/coredns/coredns-hosts-values.yaml ]; then
  echo 'Generating coredns helm chart values...'
  envsubst \
    < ${GITROOT}/bootstrap/day2-panic/coredns/coredns-hosts-values-template.yaml \
    > ${GITROOT}/bootstrap/day2-panic/coredns/coredns-hosts-values.yaml
else
  echo 'coredns helm chart value file already exists, skipping generation.'
fi

helm upgrade --install coredns coredns/coredns \
  --namespace kube-system \
  --values ${GITROOT}/bootstrap/day2-panic/coredns/coredns-hosts-values.yaml \
  --reuse-values \
  --wait
