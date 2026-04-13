# DuckDNS Setup on the Windows Home Server

Use this if you want a stable hostname instead of a raw public IP for the WireGuard client config.

## Why

Your home public IP may change. A DuckDNS hostname gives the laptop a stable endpoint like:
- `myhome.duckdns.org`

## 1. Create the DuckDNS hostname

On `https://www.duckdns.org/`:
- sign in
- create a subdomain
- note the token

Example:
- subdomain: `myhomevpn`
- hostname: `myhomevpn.duckdns.org`

## 2. Test the updater script on the Windows server

From PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update-duckdns.ps1 -Subdomain myhomevpn -Token YOUR_DUCKDNS_TOKEN
```

If it works, it should print:
- `DuckDNS response: OK`
- the current public IP

## 3. Re-render the client config with the DDNS hostname

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-direct-windows.ps1 -EndpointHost myhomevpn.duckdns.org
```

Then re-import `generated\direct-client-laptop.conf` on the laptop.

## 4. Automate updates with Task Scheduler

Create a scheduled task that runs every 5 or 10 minutes.

Example action:
- Program/script:
  `powershell.exe`
- Add arguments:
  `-ExecutionPolicy Bypass -File "G:\stealth-vpn-safe\stealth-vpn-safe\scripts\update-duckdns.ps1" -Subdomain myhomevpn -Token YOUR_DUCKDNS_TOKEN`

## 5. Verify DNS resolves to your home public IP

From any machine:

```powershell
Resolve-DnsName myhomevpn.duckdns.org
```

## Notes

- Keep the DuckDNS token private.
- Once this is working, prefer the hostname in your client config instead of the raw public IP.
- If you later move to your own domain, the same principle applies, but you would automate updates against your DNS provider instead of DuckDNS.
