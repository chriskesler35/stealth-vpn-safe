# Secondary VPS Fallback Layout

This is the cleaner way to keep a TCP 443 fallback without fighting the main relay for ports.

## Why this layout exists

On a single-IP VPS, these services compete for the same listener ports:
- Caddy wants TCP 443 for HTTPS
- OpenVPN fallback wants TCP 443

A secondary VPS avoids that conflict and gives you a cleaner failure domain.

## Suggested Layout

### Primary VPS

Purpose:
- main WireGuard relay
- HTTPS reverse proxy with Caddy
- normal day-to-day remote access

Suggested DNS:
- `vpn.example.com`
- `ha.vpn.example.com`

### Secondary VPS

Purpose:
- emergency OpenVPN TCP 443 endpoint
- optional backup WireGuard relay in another provider/region

Suggested DNS:
- `fallback.example.com`

## Traffic Patterns

### Normal

```text
Client -> WireGuard -> Primary VPS -> Home gateway -> Home LAN
```

### Restrictive network fallback

```text
Client -> OpenVPN TCP 443 -> Secondary VPS -> routed path to home LAN
```

## Two implementation patterns

### Pattern A: Independent fallback path

- secondary VPS runs OpenVPN
- home gateway maintains a second tunnel to the secondary VPS
- fallback client reaches the home LAN through that second tunnel directly

This is the most robust pattern.

### Pattern B: Shared core path

- secondary VPS runs only the fallback client ingress
- traffic is forwarded onward to the primary VPS or home gateway

This can work, but it creates more moving parts and a less clean failure boundary.

Prefer Pattern A.

## Addressing Example

Primary overlay:
- `10.70.0.0/24`

Fallback overlay:
- `10.71.0.0/24`

Home gateway keeps:
- one WireGuard peer to primary VPS
- one second tunnel or VPN relationship to secondary VPS

## Operational Guidance

- keep the secondary VPS small and cheap
- use a different provider or region than the primary if possible
- test the fallback quarterly, not only during outages
- keep published apps on the primary path; use the secondary only for remote access fallback

## Files

- `docker-compose.secondary-relay.yml`
- `config/home-gateway-secondary.wg0.conf.example`
- `config/server-secondary-wg0.conf.example`
- `scripts/render-secondary-path-configs.sh`
- `docs/FALLBACK-OPENVPN.md`
- `docs/SECONDARY-DEPLOY.md`

## Recommended Order

1. Stabilize the primary WireGuard relay first.
2. Add the secondary VPS later.
3. Generate a private key on the secondary VPS.
4. Render the secondary WireGuard configs.
5. Bring up the secondary home-gateway tunnel.
6. Put OpenVPN TCP 443 on the secondary VPS.

## Render the secondary WireGuard configs

Generate a private key for the secondary VPS, then render the pair:

```bash
wg genkey | tee secondary-server.key | wg pubkey
./scripts/render-secondary-path-configs.sh --server-private-key-file ./secondary-server.key
```

This writes:
- `generated/home-gateway-secondary.wg0.conf`
- `generated/server-secondary-wg0.conf`
