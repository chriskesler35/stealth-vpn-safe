# Restrict RDP to WireGuard Only on Windows

Use this only after WireGuard remote access is already working.

Goal:
- keep RDP enabled on the Windows home server
- only allow RDP from the WireGuard subnet
- prevent broad direct LAN/WAN RDP exposure through normal firewall rules

## What the script does

- creates custom inbound firewall rules for TCP and UDP 3389 from `10.70.0.0/24`
- disables the default broad `Remote Desktop` firewall rules

## Apply the lockdown

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\lockdown-rdp-to-wireguard.ps1 -WireGuardSubnet 10.70.0.0/24
```

## Verify the rules

```powershell
Get-NetFirewallRule | Where-Object { $_.DisplayName -like 'RDP from WireGuard*' }
Get-NetFirewallRule -DisplayGroup 'Remote Desktop'
```

## Test

From the remote laptop with WireGuard active:

```powershell
mstsc /v:10.70.0.1
```

## Roll back if needed

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore-default-rdp-firewall.ps1
```

## Safety note

Do not run the lockdown script until you have already proven:
- WireGuard connects remotely
- RDP over `10.70.0.1` works

Otherwise you risk locking yourself out of RDP until you use local console access.
