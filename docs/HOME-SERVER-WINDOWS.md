# Home Server Windows Quickstart

This guide is for using a Windows server as the always-on home WireGuard peer.

Important:
- the repo is still primarily Linux-first for the VPS side
- this Windows guide covers the home-server side cleanly with PowerShell
- if you later want this Windows box to route traffic for the rest of the LAN, we can do that next after the primary tunnel is up

## 1. Install prerequisites

Install these on the Windows server:
- Git
- GitHub CLI if you want HTTPS auth via `gh`
- WireGuard for Windows

If `winget` is available:

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id WireGuard.WireGuard -e
```

## 2. Clone the repo

Using GitHub CLI:

```powershell
gh auth login
git clone https://github.com/chriskesler35/stealth-vpn-safe.git
cd stealth-vpn-safe
```

Or using SSH if already configured:

```powershell
git clone git@github.com:chriskesler35/stealth-vpn-safe.git
cd stealth-vpn-safe
```

## 3. Bootstrap the Windows home-server side

Run in PowerShell:

```powershell
.\scripts\bootstrap-windows.ps1 `
  -PublicHost vpn.example.com `
  -FallbackHost fallback.example.com `
  -AcmeEmail admin@example.com `
  -HomeLanCidr 192.168.50.0/24
```

This creates:
- `secrets\home-gateway.key`
- `secrets\client-laptop.key`
- `secrets\preshared.key`
- `secrets\fallback-preshared.key`
- `.env`
- `generated\bootstrap-summary.txt`

## 4. Get the primary relay public key

Once the primary VPS relay is up, run on the VPS:

```bash
docker exec relay-wireguard wg show wg0 public-key
```

Copy that public key back to the Windows server.

## 5. Render the Windows home/client configs

```powershell
.\scripts\render-peer-configs.ps1 -ServerPublicKey '<paste-relay-public-key>'
```

This creates:
- `generated\home-gateway.wg0.conf`
- `generated\client-laptop.conf`

## 6. Install the tunnel as a Windows service

Run PowerShell as Administrator:

```powershell
& 'C:\Program Files\WireGuard\wireguard.exe' /installtunnelservice .\generated\home-gateway.wg0.conf
```

Verify:

```powershell
& 'C:\Program Files\WireGuard\wg.exe' show
Get-Service *WireGuard*
```

## 7. Test the primary tunnel

Once the VPS side is live:

```powershell
ping 10.70.0.1
```

## 8. If you want this Windows server to route for the rest of the LAN later

That requires an additional routing/NAT step on Windows. Do not do that yet unless the primary tunnel is already working. First prove:
- the Windows server can hold the tunnel up
- it can reach the relay
- a remote client can reach the Windows server through the relay

## Send back these outputs

After steps 1 through 6, send back:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
ipconfig
route print
& 'C:\Program Files\WireGuard\wg.exe' --version
Get-Content .\generated\bootstrap-summary.txt
```

Do not paste secret key contents. The summary file is fine.
