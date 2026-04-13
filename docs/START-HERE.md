# Start Here

This repo supports multiple deployment patterns. Do not start by reading everything.

Pick the path that matches your situation.

## Fast path chooser

### A. Windows home server, personal remote access, no VPS

Use this if:
- your always-on machine at home is Windows
- you want remote access from your own laptop/phone
- you mainly want RDP over WireGuard

Read:
- `docs/DIRECT-WIREGUARD-WINDOWS.md`
- `docs/DDNS-DUCKDNS-WINDOWS.md`
- `docs/RDP-HARDENING-WINDOWS.md`

Run first:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor-windows.ps1
```

### B. Linux home gateway + VPS relay

Use this if:
- you want a hub-and-spoke setup
- your home side is Linux
- you want a more general remote access gateway for multiple services

Read:
- `docs/DEPLOY.md`
- `docs/ARCHITECTURE.md`
- `docs/ROUTER-STATIC-ROUTES.md`

Run first:

```bash
./scripts/doctor-linux.sh
```

### C. Dedicated fallback VPS

Use this only after the primary path works.

Read:
- `docs/SECONDARY-DEPLOY.md`
- `docs/FALLBACK-SECONDARY-VPS.md`
- `docs/FALLBACK-OPENVPN.md`

## Recommended order

1. Get one primary path working.
2. Prove real remote access.
3. Add DDNS if needed.
4. Harden RDP or published services.
5. Only then add fallback complexity.

## Minimum viable setup for most people

For most people pulling this repo today, the simplest useful path is:
- Windows home server
- direct WireGuard
- DDNS hostname
- RDP restricted to `10.70.0.0/24`

That is the smallest setup that still gives clean remote access without exposing RDP publicly.
