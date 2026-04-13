#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
GENERATED_DIR="$ROOT_DIR/generated"
ENV_FILE="$ROOT_DIR/.env"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

FALLBACK_HOST_OVERRIDE=""
HOME_LAN_CIDR_OVERRIDE=""
FALLBACK_WG_SERVER_ADDRESS_OVERRIDE=""
FALLBACK_HOME_GATEWAY_ADDRESS_OVERRIDE=""
SECONDARY_SERVER_PRIVATE_KEY_FILE=""
FALLBACK_WG_PORT_OVERRIDE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") --server-private-key-file <path> [options]

Options:
  --fallback-host <host>                Override FALLBACK_HOST from .env
  --home-lan-cidr <cidr>                Override HOME_LAN_CIDR from .env
  --fallback-wg-server-address <cidr>   Override FALLBACK_WG_SERVER_ADDRESS from .env
  --fallback-home-gateway-address <cidr> Override FALLBACK_HOME_GATEWAY_ADDRESS from .env
  --fallback-wg-port <port>             Override FALLBACK_WG_PORT from .env
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-private-key-file)
      SECONDARY_SERVER_PRIVATE_KEY_FILE="$2"
      shift 2
      ;;
    --fallback-host)
      FALLBACK_HOST_OVERRIDE="$2"
      shift 2
      ;;
    --home-lan-cidr)
      HOME_LAN_CIDR_OVERRIDE="$2"
      shift 2
      ;;
    --fallback-wg-server-address)
      FALLBACK_WG_SERVER_ADDRESS_OVERRIDE="$2"
      shift 2
      ;;
    --fallback-home-gateway-address)
      FALLBACK_HOME_GATEWAY_ADDRESS_OVERRIDE="$2"
      shift 2
      ;;
    --fallback-wg-port)
      FALLBACK_WG_PORT_OVERRIDE="$2"
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

if [[ -z "$SECONDARY_SERVER_PRIVATE_KEY_FILE" ]]; then
  echo "Missing required argument: --server-private-key-file" >&2
  usage
  exit 1
fi

require_cmd wg

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

FALLBACK_HOST="${FALLBACK_HOST_OVERRIDE:-${FALLBACK_HOST:-fallback.example.com}}"
HOME_LAN_CIDR="${HOME_LAN_CIDR_OVERRIDE:-${HOME_LAN_CIDR:-192.168.50.0/24}}"
FALLBACK_WG_SERVER_ADDRESS="${FALLBACK_WG_SERVER_ADDRESS_OVERRIDE:-${FALLBACK_WG_SERVER_ADDRESS:-10.71.0.1/24}}"
FALLBACK_HOME_GATEWAY_ADDRESS="${FALLBACK_HOME_GATEWAY_ADDRESS_OVERRIDE:-${FALLBACK_HOME_GATEWAY_ADDRESS:-10.71.0.2/32}}"
FALLBACK_WG_PORT="${FALLBACK_WG_PORT_OVERRIDE:-${FALLBACK_WG_PORT:-51820}}"

mkdir -p "$GENERATED_DIR"
SECONDARY_SERVER_PRIVATE_KEY="$(cat "$SECONDARY_SERVER_PRIVATE_KEY_FILE")"
HOME_GATEWAY_PRIVATE_KEY="$(cat "$SECRETS_DIR/home-gateway.key")"
HOME_GATEWAY_PUBLIC_KEY="$(wg pubkey < "$SECRETS_DIR/home-gateway.key")"
FALLBACK_PRESHARED_KEY="$(cat "$SECRETS_DIR/fallback-preshared.key")"
SECONDARY_SERVER_PUBLIC_KEY="$(wg pubkey < "$SECONDARY_SERVER_PRIVATE_KEY_FILE")"

cat > "$GENERATED_DIR/home-gateway-secondary.wg0.conf" <<EOF
[Interface]
Address = $FALLBACK_HOME_GATEWAY_ADDRESS
PrivateKey = $HOME_GATEWAY_PRIVATE_KEY
ListenPort = 51821

# Enable forwarding on the home gateway host itself:
#   sysctl -w net.ipv4.ip_forward=1
#   sysctl -w net.ipv6.conf.all.forwarding=1

[Peer]
PublicKey = $SECONDARY_SERVER_PUBLIC_KEY
PresharedKey = $FALLBACK_PRESHARED_KEY
Endpoint = $FALLBACK_HOST:$FALLBACK_WG_PORT
AllowedIPs = 10.71.0.0/24
PersistentKeepalive = 25
EOF

cat > "$GENERATED_DIR/server-secondary-wg0.conf" <<EOF
[Interface]
Address = $FALLBACK_WG_SERVER_ADDRESS
ListenPort = $FALLBACK_WG_PORT
PrivateKey = $SECONDARY_SERVER_PRIVATE_KEY
SaveConfig = false

# Enable forwarding on the VPS host itself:
#   sysctl -w net.ipv4.ip_forward=1

[Peer]
PublicKey = $HOME_GATEWAY_PUBLIC_KEY
PresharedKey = $FALLBACK_PRESHARED_KEY
AllowedIPs = $FALLBACK_HOME_GATEWAY_ADDRESS, $HOME_LAN_CIDR
PersistentKeepalive = 25
EOF

echo "Rendered: $GENERATED_DIR/home-gateway-secondary.wg0.conf"
echo "Rendered: $GENERATED_DIR/server-secondary-wg0.conf"
