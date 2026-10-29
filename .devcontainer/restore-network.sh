#!/usr/bin/env bash

cd /workspaces/open-kritt || exit 1

# Wait briefly for Docker and the Open-Kritt network to become available.
for i in $(seq 1 30); do
  if docker info >/dev/null 2>&1 &&
     docker network inspect open-kritt_default >/dev/null 2>&1; then
    ./scripts/fix-docker-network.sh
    exit $?
  fi

  sleep 2
done

echo "Open-Kritt network not available yet."
exit 1
