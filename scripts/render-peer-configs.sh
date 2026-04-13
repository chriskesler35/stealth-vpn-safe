#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
GENERATED_DIR="$ROOT_DIR/generated"
ENV_FILE="$ROOT_DIR/.env"

SERVER_PUBLIC_KEY=""
PUBLIC_HOST=""
HOME_LAN_CIDR=""
HOME_GATEWAY_ADDRESS="10.70.0.2/32"
CLIENT_ADDRESS="10.70.0.10/32"
CLIENT_DNS="10.70.0.1"

usage() {
  cat <<EOF
Usage: $(basename "$0") --server-public-key <key> [options]

Options:
  --public-host <host>           Override PUBLIC_HOST from .env
  --home-lan-cidr <cidr>         Override HOME_LAN_CIDR from .env
  --home-gateway-address <cidr>  Default: $HOME_GATEWAY_ADDRESS
  --client-address <cidr>        Default: $CLIENT_ADDRESS
  --client-dns <ip>              Default: $CLIENT_DNS
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-public-key)
      SERVER_PUBLIC_KEY="$2"
      shift 2
      ;;
    --public-host)
      PUBLIC_HOST="$2"
      shift 2
      ;;
    --home-lan-cidr)
      HOME_LAN_CIDR="$2"
      shift 2
      ;;
    --home-gateway-address)
      HOME_GATEWAY_ADDRESS="$2"
      shift 2
      ;;
    --client-address)
      CLIENT_ADDRESS="$2"
      shift 2
      ;;
    --client-dns)
      CLIENT_DNS="$2"
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

if [[ -z "$SERVER_PUBLIC_KEY" ]]; then
  echo "Missing required argument: --server-public-key" >&2
  usage
  exit 1
fi

PUBLIC_HOST_OVERRIDE="$PUBLIC_HOST"
HOME_LAN_CIDR_OVERRIDE="$HOME_LAN_CIDR"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

PUBLIC_HOST="${PUBLIC_HOST_OVERRIDE:-${PUBLIC_HOST:-vpn.example.com}}"
HOME_LAN_CIDR="${HOME_LAN_CIDR_OVERRIDE:-${HOME_LAN_CIDR:-192.168.50.0/24}}"
PRESHARED_KEY="$(cat "$SECRETS_DIR/preshared.key")"
HOME_GATEWAY_PRIVATE_KEY="$(cat "$SECRETS_DIR/home-gateway.key")"
CLIENT_PRIVATE_KEY="$(cat "$SECRETS_DIR/client-laptop.key")"

mkdir -p "$GENERATED_DIR"

cat > "$GENERATED_DIR/home-gateway.wg0.conf" <<EOF
[Interface]
Address = $HOME_GATEWAY_ADDRESS
PrivateKey = $HOME_GATEWAY_PRIVATE_KEY
ListenPort = 51820

# Enable forwarding on the home gateway host itself:
#   sysctl -w net.ipv4.ip_forward=1
#   sysctl -w net.ipv6.conf.all.forwarding=1
# Consider replacing NAT with a static route on your home router once stable.

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
Endpoint = $PUBLIC_HOST:51820
AllowedIPs = 10.70.0.0/24
PersistentKeepalive = 25
EOF

cat > "$GENERATED_DIR/client-laptop.conf" <<EOF
[Interface]
Address = $CLIENT_ADDRESS
PrivateKey = $CLIENT_PRIVATE_KEY
DNS = $CLIENT_DNS

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
Endpoint = $PUBLIC_HOST:51820
AllowedIPs = 10.70.0.0/24, $HOME_LAN_CIDR
PersistentKeepalive = 25
EOF

echo "Rendered: $GENERATED_DIR/home-gateway.wg0.conf"
echo "Rendered: $GENERATED_DIR/client-laptop.conf"
