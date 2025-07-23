#!/usr/bin/env bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

. "${GITROOT}"/bootstrap/env.sh

#THIS_SCRIPT=$(basename "${0}")
#PADDING=$(printf %-${#THIS_SCRIPT}s " ")

function check_dependencies() {
  declare -a DEPS=(
    'git'
    'wget'
    'curl'
    'vim'
    'openssl'
    'kubectl'
    'ipcalc'
    'helm'
    'crane'
    'gettext'
  )
  declare -a MISSING=()
  # Ensure dependencies are present
  for i in "${DEPS[@]}"; do
    if [[ "$i" == "gettext" ]]; then
      if ! command -v "envsubst" &> /dev/null ; then
        MISSING+=("${i}")
      fi
    else
      if ! command -v "${i}" &> /dev/null ; then
        MISSING+=("${i}")
      fi
    fi   
  done
  if [[ ${#MISSING[@]} -ne 0 ]]; then
    msg_fatal "[-] Dependencies unmet. Please verify that the following are installed and in the PATH: " "${MISSING[@]}"
  fi
}

check_dependencies
