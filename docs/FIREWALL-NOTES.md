# Firewall Notes

This starter leaves firewall policy intentionally light so it can fit different environments. Before production use, tighten it.

## Primary VPS

Allow inbound:
- UDP `51820` for WireGuard
- TCP `80` and `443` for Caddy
- SSH from your admin IPs only if possible

Deny or restrict:
- the `wg-easy` UI port should stay loopback-only unless intentionally proxied
- any unused management ports

## Secondary VPS

Allow inbound:
- UDP `51820` for the secondary WireGuard tunnel
- TCP `443` for OpenVPN fallback
- SSH from your admin IPs only if possible

## Home Gateway

Allow:
- forwarding between the VPN overlays and the LAN
- established/related return traffic

Be careful with:
- broad NAT rules that hide too much while debugging
- overlapping subnets between your LAN and VPN overlays

## Suggested Approach

1. Get the path working with minimal necessary rules.
2. Confirm routing and handshakes.
3. Restrict inbound SSH and any admin interfaces.
4. Limit published apps behind Caddy with auth or allowlists.

## Common Symptoms

- Handshake works, LAN unreachable:
  likely routing or home firewall issue
- DNS works, TCP app fails:
  likely host firewall on the internal service
- Client reaches relay but not home gateway:
  inspect `AllowedIPs`, forwarding, and return routes
