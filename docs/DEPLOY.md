# Deploy Guide

## 1. Record your rollout choices

Before you start, fill out `docs/DECISIONS.md` so you have the real values in one place.

## 2. Bootstrap secrets

Run on a Linux box or in WSL with `wg` installed:

```bash
cd stealth-vpn-safe
chmod +x scripts/*.sh
make bootstrap PUBLIC_HOST=vpn.example.com FALLBACK_HOST=fallback.example.com ACME_EMAIL=admin@example.com HOME_LAN_CIDR=192.168.50.0/24
```

If you want the WireGuard UI password hash precomputed too:

```bash
make bootstrap PUBLIC_HOST=vpn.example.com FALLBACK_HOST=fallback.example.com ACME_EMAIL=admin@example.com HOME_LAN_CIDR=192.168.50.0/24 WG_UI_PASSWORD='strong-password'
```

## 3. Review `.env`

Check:
- `PUBLIC_HOST`
- `ACME_EMAIL`
- `HOME_LAN_CIDR`
- `HOME_ASSISTANT_UPSTREAM`
- `WG_UI_PASSWORD_HASH`

## 4. Start the VPS relay

On the VPS:

```bash
docker compose up -d
```

## 5. Extract the VPS public key

After WireGuard starts:

```bash
docker exec relay-wireguard wg show wg0 public-key
```

## 6. Render the home/client configs

```bash
./scripts/render-peer-configs.sh --server-public-key '<paste-server-public-key>'
```

This writes:
- `generated/home-gateway.wg0.conf`
- `generated/client-laptop.conf`

## 7. Install the home gateway config

Copy `generated/home-gateway.wg0.conf` to the home gateway and bring it up:

```bash
sudo cp generated/home-gateway.wg0.conf /etc/wireguard/wg0.conf
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

## 8. Import the roaming client config

Import `generated/client-laptop.conf` into the WireGuard desktop or mobile app.

## 9. Verify routing

From the client:

```bash
ping 10.70.0.2
ping 192.168.50.1
```

## 10. Publish one internal app

Edit `caddy/Caddyfile` and set the upstream to the home service reachable over the tunnel, then reload Caddy:

```bash
docker compose restart caddy
```

## 11. Run a quick health check

```bash
./scripts/check-relays.sh
```

See `docs/HEALTH-CHECKS.md` for expected output and troubleshooting hints.

## Notes

- `wg-easy` is used here for simple relay management. If you want a more fully declarative setup later, replace it with a plain WireGuard service and keep the same addressing plan.
- Start with split tunnel only. Full-tunnel can come later if you actually need it.
- Prefer a static route on the home router over long-term NAT once the setup is stable. See `docs/ROUTER-STATIC-ROUTES.md`.
- Review `docs/FIREWALL-NOTES.md` before exposing anything publicly.
- When you're ready for a dedicated fallback host, continue with `docs/SECONDARY-DEPLOY.md`.
- If you want persistent home-gateway startup, see `docs/HOME-GATEWAY-SYSTEMD.md`.
- If something breaks, use `docs/TROUBLESHOOTING.md`.
