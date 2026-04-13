#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"
SECRETS_DIR="$ROOT_DIR/secrets"
GENERATED_DIR="$ROOT_DIR/generated"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

maybe_hash_wg_password() {
  if [[ -z "${WG_UI_PASSWORD:-}" ]]; then
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$WG_UI_PASSWORD"
  else
    echo ""
  fi
}

ensure_file() {
  local path="$1"
  local generator="$2"
  if [[ ! -f "$path" ]]; then
    eval "$generator" > "$path"
    chmod 600 "$path"
  fi
}

require_cmd wg
require_cmd python3
mkdir -p "$SECRETS_DIR" "$GENERATED_DIR"

ensure_file "$SECRETS_DIR/home-gateway.key" "wg genkey"
ensure_file "$SECRETS_DIR/client-laptop.key" "wg genkey"
ensure_file "$SECRETS_DIR/preshared.key" "wg genpsk"
ensure_file "$SECRETS_DIR/fallback-preshared.key" "wg genpsk"

HOME_GATEWAY_PUBLIC_KEY="$(wg pubkey < "$SECRETS_DIR/home-gateway.key")"
CLIENT_PUBLIC_KEY="$(wg pubkey < "$SECRETS_DIR/client-laptop.key")"
WG_UI_PASSWORD_HASH="$(maybe_hash_wg_password)"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
fi

python3 - <<'PY' "$ENV_FILE" "${PUBLIC_HOST:-vpn.example.com}" "${FALLBACK_HOST:-fallback.example.com}" "${ACME_EMAIL:-admin@example.com}" "${HOME_LAN_CIDR:-192.168.50.0/24}" "$WG_UI_PASSWORD_HASH"
from pathlib import Path
import sys

env_path = Path(sys.argv[1])
public_host = sys.argv[2]
fallback_host = sys.argv[3]
acme_email = sys.argv[4]
home_lan = sys.argv[5]
password_hash = sys.argv[6]
lines = env_path.read_text().splitlines()
updates = {
    "PUBLIC_HOST": public_host,
    "FALLBACK_HOST": fallback_host,
    "ACME_EMAIL": acme_email,
    "HOME_LAN_CIDR": home_lan,
}
if password_hash:
    updates["WG_UI_PASSWORD_HASH"] = password_hash
new_lines = []
seen = set()
for line in lines:
    if "=" in line and not line.strip().startswith("#"):
        key = line.split("=", 1)[0]
        if key in updates:
            new_lines.append(f"{key}={updates[key]}")
            seen.add(key)
            continue
    new_lines.append(line)
for key, value in updates.items():
    if key not in seen:
        new_lines.append(f"{key}={value}")
env_path.write_text("\n".join(new_lines) + "\n")
PY

cat > "$GENERATED_DIR/bootstrap-summary.txt" <<EOF
Home-lab relay bootstrap complete.

Generated assets:
- home gateway private key:   $SECRETS_DIR/home-gateway.key
- home gateway public key:    $HOME_GATEWAY_PUBLIC_KEY
- client private key:         $SECRETS_DIR/client-laptop.key
- client public key:          $CLIENT_PUBLIC_KEY
- primary preshared key:      $SECRETS_DIR/preshared.key
- fallback preshared key:     $SECRETS_DIR/fallback-preshared.key
- env file:                   $ENV_FILE

Next steps:
1. Review $ENV_FILE and replace any placeholder values.
2. Start the relay stack:
   docker compose up -d
3. After the relay is up, get the server public key:
   docker exec relay-wireguard wg show wg0 public-key
4. Render peer configs:
   ./scripts/render-peer-configs.sh --server-public-key <paste-key>

Optional:
- Set WG_UI_PASSWORD in your shell before running this script to precompute WG_UI_PASSWORD_HASH.
EOF

echo "Wrote $GENERATED_DIR/bootstrap-summary.txt"
echo "Review the summary, then start the relay and render peer configs."
