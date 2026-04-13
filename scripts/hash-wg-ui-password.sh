#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <plain-password>" >&2
  exit 1
fi

docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$1"
