# Architecture

## Goals

- Reach home-lab systems without exposing the home router directly
- Keep a stable public entry point on a VPS
- Use open-source components only
- Support a clean fallback path when UDP is blocked or flaky
- Make it easy to publish selected internal apps over HTTPS

## Core Components

### VPS Relay

Runs in a cloud VM with a public IP.

Responsibilities:
- accept remote WireGuard peers
- maintain a site-to-site tunnel to the home gateway
- terminate HTTPS with Caddy
- optionally publish internal apps through reverse proxy

Suggested minimum:
- 1 vCPU
- 1 to 2 GB RAM
- Ubuntu or Debian
- one public DNS record like `vpn.example.com`

### Home Gateway

A small always-on Linux box inside the home network.

Responsibilities:
- keep a persistent WireGuard tunnel to the VPS
- route traffic toward the home LAN
- optionally NAT overlay traffic into the LAN

Good choices:
- Raspberry Pi
- small NUC
- lightweight VM on Proxmox/ESXi/Hyper-V

### Remote Clients

Laptop, phone, or tablet peers.

Responsibilities:
- connect to the VPS over WireGuard
- route home traffic into the tunnel
- optionally use split-tunnel routing only for home subnets

## Reference Addressing

- WireGuard overlay: `10.70.0.0/24`
- VPS relay: `10.70.0.1`
- Home gateway: `10.70.0.2`
- Roaming clients: `10.70.0.10+`
- Home LAN example: `192.168.50.0/24`

## Traffic Flows

### 1. Remote client to home LAN

```text
Laptop -> WireGuard -> VPS relay -> WireGuard -> Home gateway -> Home LAN
```

This is the primary remote access path.

### 2. Public HTTPS to an internal app

```text
Browser -> Caddy on VPS -> reverse_proxy over WireGuard -> Home app
```

Use this only for services you intentionally want reachable from the public internet.

### 3. Admin UI

Keep the WireGuard management UI bound to localhost and expose it only through Caddy or an SSH tunnel.

## Security Controls

- use one VPS with a dedicated DNS name and ACME TLS
- use preshared keys in addition to WireGuard public keys
- keep client `AllowedIPs` narrow by default
- prefer split tunnel over full tunnel for remote clients
- put public apps behind Caddy auth, OAuth, or IP allowlists
- restrict SSH on the VPS to your admin IPs if possible
- patch the VPS and home gateway regularly
- back up WireGuard config and peer material securely

## Fallback Plan

This design is intentionally not stealth-oriented, but it can still be resilient.

### Fallback A: OpenVPN on TCP 443

When networks break or rate-limit UDP, run a separate OpenVPN service on TCP 443. This is slower than WireGuard but often survives restrictive guest Wi-Fi better.

Suggested pattern:
- keep WireGuard as primary
- add OpenVPN Community Edition as a second manual fallback
- put the OpenVPN listener on a separate host or public IP if port conflicts matter

### Fallback B: Secondary VPS Region

Add another VPS in a different region/provider.

Use it when:
- one provider has packet loss
- one route is regionally impaired
- you need a backup control point during maintenance

### Fallback C: HTTPS-only Published Apps

If VPN transport is temporarily unusable, publish only the small set of services you actually need through Caddy.

Examples:
- Home Assistant
- Gitea
- Grafana
- file browser

## Operational Notes

### Routing

On the home gateway, enable IP forwarding and ensure the LAN knows how to return traffic. The easiest method is usually NAT on the home gateway. Cleaner long-term is a static route on the home router pointing `10.70.0.0/24` to the gateway.

### DNS

You can keep it simple at first:
- remote clients use public DNS plus direct IPs/hostnames
- internal service hostnames can be added later with Pi-hole, AdGuard Home, or CoreDNS

### Monitoring

At minimum monitor:
- VPS uptime
- WireGuard latest handshake age
- disk usage
- certificate renewal status

## Implementation Roadmap

1. Stand up the VPS relay with Caddy and WireGuard.
2. Create the home gateway tunnel.
3. Verify a remote client can reach one home host.
4. Add one public app through Caddy.
5. Add fallback OpenVPN only if you actually need it.
6. Add a second VPS only after the first one is stable.
