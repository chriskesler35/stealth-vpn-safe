# Deployment Decisions

Use this to keep the rollout intentional.

## Recommended defaults

- Primary relay mode: plain WireGuard + Caddy
- Fallback layout: dedicated secondary VPS
- Primary overlay: `10.70.0.0/24`
- Fallback overlay: `10.71.0.0/24`
- Home routing: start with NAT, migrate to static routes later
- Published apps: start with one only

## Why

- plain WireGuard is easier to reason about long-term than a UI-managed peer database
- secondary fallback avoids fighting for TCP `443`
- separate overlays make troubleshooting much easier
- static routes are cleaner, but NAT is faster to get working initially

## Fill this in before rollout

- Primary host: __________________
- Fallback host: _________________
- Home LAN CIDR: _________________
- Home gateway LAN IP: ___________
- First published app: ___________
- Router type: ___________________
- Do I want NAT first or static routes first? ___________
