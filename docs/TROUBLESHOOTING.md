# Troubleshooting

## Primary tunnel up, LAN unreachable

Check:
- home gateway has IP forwarding enabled
- LAN host firewall allows traffic from `10.70.0.0/24`
- router has a static route to `10.70.0.0/24` or the home gateway is doing NAT
- `AllowedIPs` on both ends include the right subnets

## Secondary tunnel up, fallback LAN unreachable

Check:
- home gateway has a route or NAT for `10.71.0.0/24`
- fallback VPS peer config includes `192.168.50.0/24`
- no asymmetric return path between primary and fallback tunnels

## OpenVPN reachable, but home not reachable

Check:
- fallback VPS can route to the home LAN through the secondary WireGuard tunnel
- OpenVPN server config pushed the correct home route
- client imported the latest `.ovpn` profile

## Caddy up, internal app down

Check:
- upstream IP/port in `caddy/Caddyfile`
- app is reachable from the relay over the primary tunnel
- app listens on the expected interface

## Health script failures

- `primary_dns: FAIL`
  fix DNS or the `PUBLIC_HOST` value
- `primary_https: FAIL`
  Caddy may be down, blocked, or certificate setup may be incomplete
- `fallback_tcp: FAIL`
  OpenVPN may be down, the fallback VPS may be unreachable, or TCP `443` may be filtered

## Good debugging order

1. DNS
2. relay port reachability
3. WireGuard handshake age
4. direct ping to home gateway
5. direct ping to a LAN host
6. application-layer test
