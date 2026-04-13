param(
    [string]$WireGuardSubnet = '10.70.0.0/24'
)

$ErrorActionPreference = 'Stop'

Write-Host 'Creating allow rules for RDP from the WireGuard subnet only...'

Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like 'RDP from WireGuard*' } |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName 'RDP from WireGuard TCP' `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 3389 `
    -RemoteAddress $WireGuardSubnet `
    -Profile Any | Out-Null

New-NetFirewallRule -DisplayName 'RDP from WireGuard UDP' `
    -Direction Inbound `
    -Action Allow `
    -Protocol UDP `
    -LocalPort 3389 `
    -RemoteAddress $WireGuardSubnet `
    -Profile Any | Out-Null

Write-Host 'Disabling the default broad Remote Desktop firewall rules...'
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' | Set-NetFirewallRule -Enabled False

Write-Host 'Current custom RDP rules:'
Get-NetFirewallRule | Where-Object { $_.DisplayName -like 'RDP from WireGuard*' } |
    Get-NetFirewallAddressFilter |
    Format-Table -AutoSize

Write-Host ''
Write-Host 'RDP is now limited to the WireGuard subnet only.'
Write-Host 'If you need to undo this, run scripts\restore-default-rdp-firewall.ps1 as Administrator.'
