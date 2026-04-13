# Direct WireGuard on a Windows Home Server

Use this path if:
- you have one always-on Windows server at home
- you want your own devices to connect directly to it
- you do not want a VPS relay as the primary design

This is the simplest model for personal remote access.

## Topology

```text
Laptop / Phone
    |
    | WireGuard
    v
Windows Home Server
```

## When to use which endpoint

### Local LAN test

Use the Windows server's LAN IP as `EndpointHost`.

Example:
- server LAN IP: `192.168.1.128`

### Remote access over the internet

Use one of:
- your public home IP
- a DDNS name like `myhome.duckdns.org`

And port-forward UDP `51820` on the home router to the Windows server's LAN IP.

## Render the configs

From PowerShell on the Windows server:

```powershell
.\scripts\render-direct-windows.ps1 -EndpointHost 192.168.1.128
```

If you later want the client to also try reaching the home LAN through this server, add the LAN route to the client config:

```powershell
.\scripts\render-direct-windows.ps1 -EndpointHost 192.168.1.128 -IncludeHomeLanRoute -HomeLanCidr 192.168.1.0/24
```

That creates:
- `generated\direct-server.conf`
- `generated\direct-client-laptop.conf`
- `generated\direct-summary.txt`

## Install the server tunnel

Run PowerShell as Administrator:

```powershell
& 'C:\Program Files\WireGuard\wireguard.exe' /installtunnelservice .\generated\direct-server.conf
```

Verify:

```powershell
& 'C:\Program Files\WireGuard\wg.exe' show
Get-Service *WireGuard*
```

## Install the client tunnel

On the remote laptop or phone:
- import `generated\direct-client-laptop.conf` into WireGuard
- activate the tunnel

## First test

From the remote client:
- ping `10.70.0.1`

From the Windows server:
- run `wg show` and confirm a recent handshake appears

## Important note about LAN routing

The direct path works best as host-to-host first.

That means:
- remote client reaches the Windows server itself over `10.70.0.1`
- you verify the direct tunnel before trying to route the entire LAN through the Windows box

If you later want full LAN access through the Windows server, that becomes a Windows routing/NAT step and should be done only after the direct tunnel works.
