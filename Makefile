SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PUBLIC_HOST ?= vpn.example.com
FALLBACK_HOST ?= fallback.example.com
ACME_EMAIL ?= admin@example.com
HOME_LAN_CIDR ?= 192.168.50.0/24
FALLBACK_OPENVPN_PORT ?= 443

help:
	@echo "Targets:"
	@echo "  bootstrap            Generate local secrets and starter .env"
	@echo "  up-primary           Start primary relay with wg-easy + Caddy"
	@echo "  up-core              Start primary relay with plain WireGuard + Caddy"
	@echo "  down-primary         Stop primary wg-easy relay stack"
	@echo "  down-core            Stop primary plain-WireGuard relay stack"
	@echo "  render-primary       Render primary home/client configs (SERVER_PUBLIC_KEY=...)"
	@echo "  render-secondary     Render secondary fallback WireGuard configs (SECONDARY_SERVER_KEY_FILE=... )"
	@echo "  init-openvpn         Initialize fallback OpenVPN config"
	@echo "  up-secondary         Start secondary fallback VPS stack"
	@echo "  down-secondary       Stop secondary fallback VPS stack"
	@echo "  check                Run relay health checks"
	@echo "  hash-ui-password     Hash WG_UI_PASSWORD via wg-easy helper"

bootstrap:
	chmod +x scripts/*.sh
	PUBLIC_HOST='$(PUBLIC_HOST)' FALLBACK_HOST='$(FALLBACK_HOST)' ACME_EMAIL='$(ACME_EMAIL)' HOME_LAN_CIDR='$(HOME_LAN_CIDR)' ./scripts/bootstrap-linux.sh

up-primary:
	docker compose up -d

up-core:
	docker compose -f docker-compose.wireguard-core.yml up -d

down-primary:
	docker compose down

down-core:
	docker compose -f docker-compose.wireguard-core.yml down

render-primary:
	@test -n "$(SERVER_PUBLIC_KEY)" || (echo "Set SERVER_PUBLIC_KEY=<relay-public-key>" >&2; exit 1)
	./scripts/render-peer-configs.sh --server-public-key '$(SERVER_PUBLIC_KEY)'

render-secondary:
	@test -n "$(SECONDARY_SERVER_KEY_FILE)" || (echo "Set SECONDARY_SERVER_KEY_FILE=./secondary-server.key" >&2; exit 1)
	./scripts/render-secondary-path-configs.sh --server-private-key-file '$(SECONDARY_SERVER_KEY_FILE)'

init-openvpn:
	chmod +x scripts/*.sh
	FALLBACK_HOST='$(FALLBACK_HOST)' HOME_LAN_CIDR='$(HOME_LAN_CIDR)' FALLBACK_OPENVPN_PORT='$(FALLBACK_OPENVPN_PORT)' ./scripts/init-openvpn.sh

up-secondary:
	docker compose -f docker-compose.secondary-relay.yml up -d

down-secondary:
	docker compose -f docker-compose.secondary-relay.yml down

check:
	chmod +x scripts/*.sh
	./scripts/check-relays.sh

hash-ui-password:
	@test -n "$(WG_UI_PASSWORD)" || (echo "Set WG_UI_PASSWORD=<plain-password>" >&2; exit 1)
	./scripts/hash-wg-ui-password.sh '$(WG_UI_PASSWORD)'
