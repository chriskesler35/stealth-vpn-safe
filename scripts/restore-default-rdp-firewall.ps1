$ErrorActionPreference = 'Stop'

Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like 'RDP from WireGuard*' } |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

Get-NetFirewallRule -DisplayGroup 'Remote Desktop' | Set-NetFirewallRule -Enabled True

Write-Host 'Restored the default Remote Desktop firewall rules.'
