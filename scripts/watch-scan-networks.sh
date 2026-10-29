#!/usr/bin/env bash
set -euo pipefail

repair_network() {
  local network="$1"
  local id subnet bridge

  id="$(docker network inspect "$network" --format '{{.Id}}' 2>/dev/null)" || return 0
  subnet="$(docker network inspect "$network" --format '{{(index .IPAM.Config 0).Subnet}}' 2>/dev/null)" || return 0

  [[ -n "$id" && -n "$subnet" ]] || return 0
  bridge="br-${id:0:12}"

  sudo iptables-legacy -C FORWARD -i "$bridge" -o "$bridge" -j ACCEPT 2>/dev/null ||
    sudo iptables-legacy -I FORWARD 1 -i "$bridge" -o "$bridge" -j ACCEPT

  sudo iptables-legacy -C FORWARD -i "$bridge" ! -o "$bridge" -j ACCEPT 2>/dev/null ||
    sudo iptables-legacy -I FORWARD 1 -i "$bridge" ! -o "$bridge" -j ACCEPT

  sudo iptables-legacy -C FORWARD -o "$bridge" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
    sudo iptables-legacy -I FORWARD 1 -o "$bridge" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

  sudo iptables-legacy -t nat -C POSTROUTING -s "$subnet" ! -o "$bridge" -j MASQUERADE 2>/dev/null ||
    sudo iptables-legacy -t nat -I POSTROUTING 1 -s "$subnet" ! -o "$bridge" -j MASQUERADE

  echo "Network repaired: $network"
}

declare -A repaired_networks=()

echo "Watching Open-Kritt scan networks..."

while true; do
  while read -r network; do
    if [[ -n "$network" && -z "${repaired_networks[$network]:-}" ]]; then
      repair_network "$network"
      repaired_networks["$network"]=1
    fi
  done < <(
    docker network ls \
      --filter label=open-kritt.scan-sandbox=1 \
      --format '{{.Name}}'
  )

  sleep 2
done
