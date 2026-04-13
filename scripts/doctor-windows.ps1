$ErrorActionPreference = 'Stop'

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Find-WireGuardExe {
    $candidates = @(
        'C:\Program Files\WireGuard\wireguard.exe',
        'C:\Program Files\WireGuard\wg.exe'
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

Write-Host 'Windows Doctor'
Write-Host '=============='

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host "Repo root: $repoRoot"
Write-Host "PowerShell: $($PSVersionTable.PSVersion)"

$gitOk = Test-CommandExists 'git'
$ghOk = Test-CommandExists 'gh'
$wgPath = Find-WireGuardExe

Write-Host "Git installed:           $gitOk"
Write-Host "GitHub CLI installed:    $ghOk"
Write-Host "WireGuard installed:     $([bool]$wgPath)"
if ($wgPath) {
    Write-Host "WireGuard path:          $wgPath"
}

Write-Host ''
Write-Host 'Network summary:'
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength |
    Format-Table -AutoSize

Write-Host ''
Write-Host 'Suggested next step:'
if (-not $wgPath) {
    Write-Host '  Install WireGuard for Windows first.'
} elseif (Test-Path (Join-Path $repoRoot 'generated\direct-server.conf')) {
    Write-Host '  Direct Windows config already rendered. If needed, install the tunnel service:'
    Write-Host "  & '$wgPath' /installtunnelservice '$repoRoot\generated\direct-server.conf'"
} else {
    Write-Host '  Render the direct Windows config:'
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\render-direct-windows.ps1 -EndpointHost <LAN-IP-or-DDNS>"
}
