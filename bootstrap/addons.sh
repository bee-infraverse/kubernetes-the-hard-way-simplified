#!/bin/bash
# Enable bash's unofficial strict mode
GITROOT=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/strict-mode
# shellcheck disable=SC1090,SC1091
. "${GITROOT}"/lib/utils
strictMode

SCRIPT_DIR="${GITROOT}/bootstrap/addons"

# Check if directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
  echo "❌ Directory '$SCRIPT_DIR' not found!"
  exit 1
fi

# Find all *.sh files, sort them, and execute
for script in $(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "*.sh" | sort); do
  echo "🚀 Running: $script"
  bash "$script"
  echo "✅ Done: $script"
  echo "-----------------------------"
done
