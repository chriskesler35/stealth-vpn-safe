#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
PRIMARY_HOST=""

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}
FALLBACK_HOST=""
FALLBACK_OPENVPN_PORT="443"
PRIMARY_HTTPS_URL=""
WG_IFACES=(wg0 wg-fallback)

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

PRIMARY_HOST="${PUBLIC_HOST:-}"
FALLBACK_HOST="${FALLBACK_HOST:-}"
PRIMARY_HTTPS_URL="https://${PRIMARY_HOST:-localhost}"
FALLBACK_OPENVPN_PORT="${FALLBACK_OPENVPN_PORT:-443}"

require_cmd python3

python3 - <<'PY' "$PRIMARY_HOST" "$FALLBACK_HOST" "$PRIMARY_HTTPS_URL" "$FALLBACK_OPENVPN_PORT"
import socket
import ssl
import sys
import urllib.request

primary_host, fallback_host, primary_url, fallback_port = sys.argv[1:5]


def check_dns(host):
    if not host:
        return False, "unset"
    try:
        ip = socket.gethostbyname(host)
        return True, ip
    except Exception as exc:
        return False, str(exc)


def check_https(url):
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=5, context=ssl.create_default_context()) as resp:
            return True, str(resp.status)
    except Exception as exc:
        return False, str(exc)


def check_tcp(host, port):
    if not host:
        return False, "unset"
    try:
        with socket.create_connection((host, int(port)), timeout=5):
            return True, f"tcp/{port} reachable"
    except Exception as exc:
        return False, str(exc)

checks = [
    ("primary_dns",) + check_dns(primary_host),
    ("primary_https",) + check_https(primary_url),
    ("fallback_dns",) + check_dns(fallback_host),
    ("fallback_tcp",) + check_tcp(fallback_host, fallback_port),
]

for name, ok, detail in checks:
    state = "OK" if ok else "FAIL"
    print(f"{name}: {state} ({detail})")
PY

if command -v wg >/dev/null 2>&1; then
  echo "local_wireguard:"
  for iface in "${WG_IFACES[@]}"; do
    if wg show "$iface" >/dev/null 2>&1; then
      echo "  interface $iface: present"
      wg show "$iface" latest-handshakes | while read -r peer ts; do
        if [[ "$ts" == "0" ]]; then
          echo "    peer $peer: no handshake yet"
        else
          now="$(date +%s)"
          age=$((now - ts))
          echo "    peer $peer: latest handshake ${age}s ago"
        fi
      done
    fi
  done
fi
