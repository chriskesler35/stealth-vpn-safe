# stealth-vpn-safe

Safe, open-source remote access starter built around WireGuard.

This repo now has one clear default path:
- **most people should start with direct WireGuard to a Windows home server**
- the **VPS relay** and **fallback** designs are still included, but they are advanced paths

It is intended for personal remote access, home labs, and self-hosted services.

It is **not** intended to hide traffic from enterprise inspection, evade corporate controls, or bypass network policy.

## Best Starting Point

If you want the fastest path to a working setup, start here:

- Windows home server + direct WireGuard: `docs/DIRECT-WIREGUARD-WINDOWS.md`
- Windows prerequisite check: `powershell -ExecutionPolicy Bypass -File .\scripts\doctor-windows.ps1`
- Linux prerequisite check: `./scripts/doctor-linux.sh`
- General path chooser: `docs/START-HERE.md`

## Common Use Case

The most common setup for this repo is:
- one always-on Windows server at home
- one laptop or phone connecting remotely
- RDP over WireGuard
- no public RDP exposure
- optional DDNS for changing home IPs

Topology:

```text
Laptop / Phone
    |
    | WireGuard
    v
Windows Home Server
```

## Quickstart: Direct Windows Setup

1. Install WireGuard on the Windows home server.
2. Run the Windows doctor script.
3. Bootstrap the repo.
4. Render the direct server/client configs.
5. Install the server tunnel as a Windows service.
6. Port-forward UDP `51820` on the home router.
7. Import the client config on the laptop or phone.
8. RDP to `10.70.0.1` over the VPN.

Main docs for that path:
- `docs/DIRECT-WIREGUARD-WINDOWS.md`
- `docs/DDNS-DUCKDNS-WINDOWS.md`
- `docs/RDP-HARDENING-WINDOWS.md`
- `docs/WINDOWS-GATEWAY-NOTES.md`

## Other Supported Paths

### Linux Home Gateway + VPS Relay

Use this if you want a more general remote-access gateway with a public relay VPS.

Read:
- `docs/DEPLOY.md`
- `docs/ARCHITECTURE.md`
- `docs/HOME-SERVER-QUICKSTART.md`
- `docs/HOME-SERVER-WINDOWS.md`

Topology:

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
+-------------------+
        |
        | WireGuard site-to-site tunnel
        v
+-------------------+
| Home Gateway      |
| - Linux VM/Pi     |
| - Routes home LAN |
+-------------------+
        |
        v
  Home services and devices
```

### Dedicated Fallback VPS

Use this only after the primary path works.

Read:
- `docs/SECONDARY-DEPLOY.md`
- `docs/FALLBACK-SECONDARY-VPS.md`
- `docs/FALLBACK-OPENVPN.md`

## What’s In The Repo

### Scripts

- `scripts/doctor-windows.ps1` - Windows prerequisite and next-step check
- `scripts/doctor-linux.sh` - Linux prerequisite and next-step check
- `scripts/bootstrap-windows.ps1` - bootstrap secrets and `.env` on Windows
- `scripts/bootstrap-linux.sh` - bootstrap secrets and `.env` on Linux
- `scripts/render-direct-windows.ps1` - generate direct Windows server/client WireGuard configs
- `scripts/render-peer-configs.ps1` - render Windows-side relay peer configs
- `scripts/render-peer-configs.sh` - render Linux relay peer configs
- `scripts/render-server-config.sh` - render plain WireGuard server config
- `scripts/render-secondary-path-configs.sh` - render the fallback WireGuard pair
- `scripts/update-duckdns.ps1` - update DuckDNS from the Windows home server
- `scripts/lockdown-rdp-to-wireguard.ps1` - restrict RDP to the WireGuard subnet
- `scripts/restore-default-rdp-firewall.ps1` - undo the RDP lockdown
- `scripts/check-relays.sh` - relay health checks
- `scripts/init-openvpn.sh` - initialize OpenVPN fallback config
- `scripts/hash-wg-ui-password.sh` - helper for `wg-easy`

### Core Docs

- `docs/START-HERE.md` - choose the right deployment path
- `docs/DECISIONS.md` - fill in your real values before rollout
- `docs/TROUBLESHOOTING.md` - debugging order and likely failure modes
- `docs/FIREWALL-NOTES.md` - firewall guidance
- `docs/ROUTER-STATIC-ROUTES.md` - moving from NAT to static routes
- `docs/HEALTH-CHECKS.md` - verification helpers

### Windows-Focused Docs

- `docs/DIRECT-WIREGUARD-WINDOWS.md`
- `docs/HOME-SERVER-WINDOWS.md`
- `docs/DDNS-DUCKDNS-WINDOWS.md`
- `docs/RDP-HARDENING-WINDOWS.md`
- `docs/WINDOWS-GATEWAY-NOTES.md`

### Linux / Relay / Advanced Docs

- `docs/DEPLOY.md`
- `docs/ARCHITECTURE.md`
- `docs/PLAIN-WIREGUARD.md`
- `docs/HOME-SERVER-QUICKSTART.md`
- `docs/HOME-GATEWAY-SYSTEMD.md`
- `docs/SECONDARY-DEPLOY.md`
- `docs/FALLBACK-SECONDARY-VPS.md`
- `docs/FALLBACK-OPENVPN.md`

## Repo Layout

```text
stealth-vpn-safe/
├── .env.example
├── LICENSE
├── Makefile
├── docker-compose.yml
├── docker-compose.openvpn.yml
├── docker-compose.secondary-relay.yml
├── docker-compose.wireguard-core.yml
├── caddy/
├── config/
├── docs/
├── scripts/
└── systemd/
```

## Notes

- The **Windows direct path** is the best starting point for personal remote RDP access.
- The VPS relay path is more flexible, but it is not the simplest first deployment.
- The fallback/OpenVPN material is intentionally secondary and should be added only after the primary path works.
- The sample primary overlay is `10.70.0.0/24`.
- The sample fallback overlay is `10.71.0.0/24`.
- This repo includes both Windows and Linux setup material, but the relay side still assumes Linux.
- Review and adapt firewall rules, addressing, and router settings before production use.

## License

MIT. See `LICENSE`.
