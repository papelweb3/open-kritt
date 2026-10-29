#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/open-kritt

echo "Restoring Open-Kritt permissions..."

if [ -d .data/engine ]; then
  sudo chown -R "$(id -u):$(id -g)" .data/engine
  sudo chmod -R u+rwX .data/engine
fi

echo "Open-Kritt permissions restored."
