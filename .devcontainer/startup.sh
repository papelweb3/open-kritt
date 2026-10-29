#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/open-kritt

echo "Starting Open-Kritt environment setup..."

echo "1. Restoring permissions..."
bash .devcontainer/restore-permissions.sh

echo "2. Restoring Docker networking..."
bash .devcontainer/restore-network.sh

echo "Open-Kritt environment setup complete."


echo "3. Starting scan network watcher..."

if ! pgrep -f '^bash scripts/watch-scan-networks.sh$' >/dev/null; then
  nohup bash scripts/watch-scan-networks.sh     > /tmp/open-kritt-network-watcher.log 2>&1 < /dev/null &
fi

echo "Scan network watcher ready."
