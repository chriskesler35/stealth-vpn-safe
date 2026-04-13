#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
GENERATED_DIR="$ROOT_DIR/generated"
SERVER_ADDRESS="10.70.0.1/24"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}
HOME_GATEWAY_ADDRESS="10.70.0.2/32"
HOME_LAN_CIDR="192.168.50.0/24"
CLIENT_ADDRESS="10.70.0.10/32"

usage() {
  cat <<EOF
Usage: $(basename "$0") --server-private-key-file <path> [options]

Options:
  --server-address <cidr>        Default: $SERVER_ADDRESS
  --home-gateway-address <cidr>  Default: $HOME_GATEWAY_ADDRESS
  --home-lan-cidr <cidr>         Default: $HOME_LAN_CIDR
  --client-address <cidr>        Default: $CLIENT_ADDRESS
EOF
}

SERVER_PRIVATE_KEY_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-private-key-file)
      SERVER_PRIVATE_KEY_FILE="$2"
      shift 2
      ;;
    --server-address)
      SERVER_ADDRESS="$2"
      shift 2
      ;;
    --home-gateway-address)
      HOME_GATEWAY_ADDRESS="$2"
      shift 2
      ;;
    --home-lan-cidr)
      HOME_LAN_CIDR="$2"
      shift 2
      ;;
    --client-address)
      CLIENT_ADDRESS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SERVER_PRIVATE_KEY_FILE" ]]; then
  echo "Missing required argument: --server-private-key-file" >&2
  usage
  exit 1
fi

require_cmd wg
mkdir -p "$GENERATED_DIR"
SERVER_PRIVATE_KEY="$(cat "$SERVER_PRIVATE_KEY_FILE")"
HOME_GATEWAY_PUBLIC_KEY="$(wg pubkey < "$SECRETS_DIR/home-gateway.key")"
CLIENT_PUBLIC_KEY="$(wg pubkey < "$SECRETS_DIR/client-laptop.key")"
PRESHARED_KEY="$(cat "$SECRETS_DIR/preshared.key")"

cat > "$GENERATED_DIR/server-wg0.conf" <<EOF
[Interface]
Address = $SERVER_ADDRESS
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
SaveConfig = false

# Enable forwarding on the VPS host itself:
#   sysctl -w net.ipv4.ip_forward=1

[Peer]
PublicKey = $HOME_GATEWAY_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = $HOME_GATEWAY_ADDRESS, $HOME_LAN_CIDR
PersistentKeepalive = 25

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = $CLIENT_ADDRESS
PersistentKeepalive = 25
EOF

echo "Rendered: $GENERATED_DIR/server-wg0.conf"
