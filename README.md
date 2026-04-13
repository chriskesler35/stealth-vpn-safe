# Home-Lab Remote Access Gateway with VPS Relay

This is a safe, open-source starter for a Tailscale-like remote access setup without relying on a commercial control plane.

It is designed for:
- remote access to a home lab behind NAT
- a public VPS relay with a stable IP
- WireGuard for fast private connectivity
- Caddy for publishing selected internal services over HTTPS
- optional fallback transports documented in the architecture notes

It is not designed to evade network policy, hide traffic from enterprise inspection, or bypass corporate controls.

## Topology

```text
Remote Laptop/Phone
        |
        | WireGuard
        v
+-------------------+
| VPS Relay         |
| - Public IP       |
| - WireGuard hub   |
| - Caddy           |
| - Optional UI     |
+-------------------+
        |
        | WireGuard site-to-site tunnel
        v
+-------------------+
| Home Gateway      |
| - Small VM/Pi     |
| - Routes home LAN |
+-------------------+
        |
        v
  Home services and devices
```

## What You Get

- `docker-compose.yml` for the VPS relay
- `caddy/Caddyfile` with examples for publishing services through the tunnel
- `.env.example` for deployment variables
- `config/home-gateway.wg0.conf.example` for the home peer
- `config/client-laptop.conf.example` for a roaming client
- `scripts/bootstrap-linux.sh` to generate keys, preshared keys, and a starter `.env`
- `scripts/render-peer-configs.sh` to render the primary home gateway and roaming client configs once the relay has a public key
- `scripts/render-server-config.sh` to render a plain WireGuard server config if you want to avoid `wg-easy`
- `scripts/render-secondary-path-configs.sh` to render the secondary-VPS fallback WireGuard pair
- `scripts/init-openvpn.sh` to generate a TCP 443 OpenVPN fallback config
- `Makefile` for common bootstrap, render, start, and health-check tasks
- `scripts/check-relays.sh` to verify the main and fallback relay endpoints quickly
- `docs/ARCHITECTURE.md` with network plan, routing, and fallback guidance
- `docs/DEPLOY.md` with a concrete deployment sequence
- `docs/PLAIN-WIREGUARD.md` for the file-based relay option
- `docs/FALLBACK-OPENVPN.md` for emergency TCP 443 fallback deployment
- `docs/FALLBACK-SECONDARY-VPS.md` for the cleaner two-VPS fallback layout
- `docs/SECONDARY-DEPLOY.md` for the dedicated fallback-VPS rollout
- `docs/HOME-GATEWAY-SYSTEMD.md` for persistent tunnel startup on the home gateway
- `docs/HEALTH-CHECKS.md` for relay verification
- `docs/ROUTER-STATIC-ROUTES.md` for moving from NAT to cleaner LAN routing
- `docs/FIREWALL-NOTES.md` for host and relay firewall guidance
- `docs/TROUBLESHOOTING.md` for common failure modes
- `docs/DECISIONS.md` as a rollout checklist

## Design Summary

- The VPS is the rendezvous point with a stable public IP or DNS name.
- The home gateway keeps a persistent WireGuard tunnel to the VPS.
- Remote clients connect to the VPS and reach home resources through the home gateway.
- Selected home services can also be published through Caddy on the VPS without exposing the home router directly.

## Recommended Deployment Order

1. Fill out `docs/DECISIONS.md` with your real hostnames, LAN CIDR, and first app.
2. Run `make bootstrap` to generate secrets and a starter `.env`.
3. Choose a relay mode: `wg-easy` for convenience or plain WireGuard for a file-based setup.
4. Bring up the VPS relay.
5. Render the peer configs once the relay exposes its WireGuard public key.
6. Connect the home gateway to the VPS.
7. Connect one roaming client.
8. Add reverse-proxied home services in Caddy one by one.
9. Move from NAT to static routes using `docs/ROUTER-STATIC-ROUTES.md` once the path is stable.
10. Add the secondary fallback VPS if you need a more resilient path.

## Repo Layout

```text
stealth-vpn-safe/
├── .env.example
├── Makefile
├── docker-compose.yml
├── docker-compose.openvpn.yml
├── docker-compose.secondary-relay.yml
├── docker-compose.wireguard-core.yml
├── caddy/
│   └── Caddyfile
├── config/
│   ├── client-laptop.conf.example
│   ├── client-laptop.ovpn.notes.txt
│   ├── home-gateway-secondary.wg0.conf.example
│   ├── home-gateway.wg0.conf.example
│   ├── server-secondary-wg0.conf.example
│   └── server-wg0.conf.example
├── scripts/
│   ├── bootstrap-linux.sh
│   ├── check-relays.sh
│   ├── hash-wg-ui-password.sh
│   ├── init-openvpn.sh
│   ├── render-peer-configs.sh
│   ├── render-secondary-path-configs.sh
│   └── render-server-config.sh
├── systemd/
│   └── home-gateway/
│       ├── 99-home-gateway-forwarding.conf
│       ├── wg-primary.service
│       └── wg-secondary.service
└── docs/
    ├── ARCHITECTURE.md
    ├── DECISIONS.md
    ├── DEPLOY.md
    ├── FALLBACK-OPENVPN.md
    ├── FALLBACK-SECONDARY-VPS.md
    ├── FIREWALL-NOTES.md
    ├── HEALTH-CHECKS.md
    ├── HOME-GATEWAY-SYSTEMD.md
    ├── PLAIN-WIREGUARD.md
    ├── ROUTER-STATIC-ROUTES.md
    ├── SECONDARY-DEPLOY.md
    └── TROUBLESHOOTING.md
```

## Notes

- This starter assumes Linux for the VPS and home gateway.
- The sample home LAN CIDR is `192.168.50.0/24`.
- The sample WireGuard overlay is `10.70.0.0/24`.
- The sample OpenVPN and secondary fallback subnet is `10.71.0.0/24`.
- On a single-IP VPS, OpenVPN on TCP 443 is a mutually exclusive fallback unless you add a second public IP or separate fallback host.
- The bootstrap now generates separate preshared keys for the primary and fallback paths.
- I have not deployed this in your environment, so treat the configs as a starter and adjust interface names, DNS, and firewall rules before going live.
