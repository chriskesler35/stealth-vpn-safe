#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENVPN_DIR="$ROOT_DIR/openvpn"
FALLBACK_HOST="${FALLBACK_HOST:-${PUBLIC_HOST:-}}"
HOME_LAN_CIDR="${HOME_LAN_CIDR:-192.168.50.0/24}"
OPENVPN_SUBNET="${OPENVPN_SUBNET:-10.71.0.0/24}"
FALLBACK_OPENVPN_PORT="${FALLBACK_OPENVPN_PORT:-443}"

usage() {
  cat <<EOF
Usage:
  FALLBACK_HOST=fallback.example.com [HOME_LAN_CIDR=192.168.50.0/24] ./scripts/init-openvpn.sh

Environment:
  FALLBACK_HOST        Required. Public DNS name for the OpenVPN endpoint.
  HOME_LAN_CIDR        Default: 192.168.50.0/24
  OPENVPN_SUBNET       Default: 10.71.0.0/24
  FALLBACK_OPENVPN_PORT Default: 443
EOF
}

if [[ -z "$FALLBACK_HOST" ]]; then
  echo "Missing FALLBACK_HOST" >&2
  usage
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Missing required command: docker" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Missing required command: python3" >&2
  exit 1
fi

mkdir -p "$OPENVPN_DIR"

read -r ROUTE_NET ROUTE_MASK < <(
python3 - <<'PY' "$HOME_LAN_CIDR"
import ipaddress, sys
net = ipaddress.ip_network(sys.argv[1], strict=False)
print(net.network_address, net.netmask)
PY
)

echo "Initializing OpenVPN config in $OPENVPN_DIR"
docker run --rm -v "$OPENVPN_DIR:/etc/openvpn" kylemanna/openvpn:2.6 \
  ovpn_genconfig -u "tcp://$FALLBACK_HOST:$FALLBACK_OPENVPN_PORT" -s "$OPENVPN_SUBNET" -p "route $ROUTE_NET $ROUTE_MASK"

cat <<EOF

Base OpenVPN server config generated.

Next steps:
1. Initialize the PKI interactively:
   docker run -it --rm -v "$OPENVPN_DIR:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_initpki
2. Start the fallback server:
   docker compose -f docker-compose.openvpn.yml up -d
3. Create a client certificate:
   docker run -it --rm -v "$OPENVPN_DIR:/etc/openvpn" kylemanna/openvpn:2.6 easyrsa build-client-full laptop nopass
4. Export the client profile:
   docker run --rm -v "$OPENVPN_DIR:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_getclient laptop > generated/client-laptop.ovpn

Remember:
- This fallback expects the relay host to already know how to route home LAN traffic.
- On a single-IP VPS, TCP 443 conflicts with Caddy. Stop the HTTPS relay first, use a second IP, or run this on a separate host.
EOF
