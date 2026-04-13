#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

has() {
  command -v "$1" >/dev/null 2>&1
}

echo "Linux Doctor"
echo "============"
echo "Repo root: $repo_root"
echo
printf "%-24s %s\n" "git installed:" "$(has git && echo yes || echo no)"
printf "%-24s %s\n" "docker installed:" "$(has docker && echo yes || echo no)"
printf "%-24s %s\n" "wg installed:" "$(has wg && echo yes || echo no)"
printf "%-24s %s\n" "python3 installed:" "$(has python3 && echo yes || echo no)"
echo

echo "IPv4 addresses:"
ip -4 addr | sed 's/^/  /'
echo

echo "Suggested next step:"
if [[ -f "$repo_root/.env" ]]; then
  echo "  .env already exists. Review docs/DEPLOY.md and continue from relay startup."
else
  echo "  Run: ./scripts/bootstrap-linux.sh"
fi
