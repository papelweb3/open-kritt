#!/usr/bin/env bash
set -euo pipefail

NETWORK="open-kritt_default"

BRIDGE="br-$(docker network inspect "$NETWORK" --format '{{.Id}}' | cut -c1-12)"
SUBNET="$(docker network inspect "$NETWORK" --format '{{(index .IPAM.Config 0).Subnet}}')"

echo "Repairing Docker network: $NETWORK"
echo "Bridge: $BRIDGE"
echo "Subnet: $SUBNET"

# Allow communication between containers
sudo iptables-legacy -C FORWARD -i "$BRIDGE" -o "$BRIDGE" -j ACCEPT 2>/dev/null ||
sudo iptables-legacy -I FORWARD 1 -i "$BRIDGE" -o "$BRIDGE" -j ACCEPT

# Allow outbound traffic
sudo iptables-legacy -C FORWARD -i "$BRIDGE" ! -o "$BRIDGE" -j ACCEPT 2>/dev/null ||
sudo iptables-legacy -I FORWARD 1 -i "$BRIDGE" ! -o "$BRIDGE" -j ACCEPT

# Allow return traffic
sudo iptables-legacy -C FORWARD -o "$BRIDGE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
sudo iptables-legacy -I FORWARD 1 -o "$BRIDGE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Allow outbound NAT
sudo iptables-legacy -t nat -C POSTROUTING -s "$SUBNET" ! -o "$BRIDGE" -j MASQUERADE 2>/dev/null ||
sudo iptables-legacy -t nat -I POSTROUTING 1 -s "$SUBNET" ! -o "$BRIDGE" -j MASQUERADE

echo "Docker network rules restored successfully."
