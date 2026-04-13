# Windows Security Audit

Use this after the direct Windows WireGuard setup is working.

This is a read-only audit path. It helps you confirm the system is shaped the way you expect before you harden further.

## Run the audit

Open PowerShell as Administrator and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\security-audit-windows.ps1
```

## What the audit checks

- OS version and interfaces
- current routes
- WireGuard version, live state, and service startup mode
- listening TCP and UDP ports
- default Remote Desktop firewall rules
- custom `RDP from WireGuard*` rules
- the WireGuard UDP 51820 firewall rule
- whether RDP is enabled
- whether NLA is required
- `TermService` startup state
- BitLocker status
- Windows Firewall profile defaults
- Windows Update service state
- current public IP

## What “good” looks like

For the direct Windows path, a strong baseline is:
- WireGuard tunnel service is `Running` and `Auto`
- WireGuard listens on UDP `51820`
- no router forward exists for TCP `3389`
- default broad Remote Desktop firewall rules are disabled after lockdown
- custom RDP rules allow only `10.70.0.0/24`
- RDP uses NLA
- BitLocker is enabled on the system volume
- Windows Firewall profiles are enabled
- Windows Update service is available and normal

## What to fix immediately if you see it

- broad RDP firewall rules still enabled after lockdown
- WireGuard service not set to Auto
- BitLocker off on a portable or theft-risk system
- Windows Firewall disabled
- unexpected internet-facing listeners beyond the few you intended

## Suggested sequence

1. Run the audit.
2. Review the RDP rules.
3. Confirm DDNS is working.
4. Apply RDP lockdown if not already done.
5. Re-run the audit.
