# Relay Health Checks

Use the helper script to verify the main and fallback control points quickly.

## Script

- `scripts/check-relays.sh`

It reads `.env` and checks:
- primary relay DNS resolution
- primary HTTPS reachability
- fallback relay DNS resolution
- fallback TCP reachability on the OpenVPN port
- local WireGuard handshake ages if run on a host with `wg`

## Usage

```bash
cd stealth-vpn-safe
chmod +x scripts/*.sh
./scripts/check-relays.sh
```

## Expected Output

```text
primary_dns: OK (...)
primary_https: OK (200)
fallback_dns: OK (...)
fallback_tcp: OK (tcp/443 reachable)
local_wireguard:
  interface wg0: present
    peer <peer-key>: latest handshake 18s ago
```

## Notes

- `primary_https` assumes the main relay serves HTTPS through Caddy.
- `fallback_tcp` is just a reachability check, not a full OpenVPN protocol check.
- If you run the script from a client machine without local WireGuard interfaces, the remote checks still work.
