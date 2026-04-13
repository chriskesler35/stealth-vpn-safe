param(
    [Parameter(Mandatory = $true)][string]$EndpointHost,
    [int]$ListenPort = 51820,
    [string]$ServerAddress = '10.70.0.1/24',
    [string]$ClientAddress = '10.70.0.10/32',
    [string]$HomeLanCidr,
    [switch]$IncludeHomeLanRoute
)

$ErrorActionPreference = 'Stop'

function Get-WgExe {
    $candidates = @(
        'C:\Program Files\WireGuard\wg.exe',
        'C:\Program Files\WireGuard\wgx.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }

    $cmd = Get-Command wg.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    throw 'Could not find wg.exe. Install WireGuard for Windows first.'
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$secretsDir = Join-Path $root 'secrets'
$generatedDir = Join-Path $root 'generated'
$envFile = Join-Path $root '.env'
$wg = Get-WgExe

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(?<key>[^#=]+)=(?<value>.*)$') {
            Set-Variable -Name $matches['key'] -Value $matches['value'] -Scope Script
        }
    }
}

if (-not $HomeLanCidr -and $script:HOME_LAN_CIDR) {
    $HomeLanCidr = $script:HOME_LAN_CIDR
}

$serverPrivateKey = (Get-Content (Join-Path $secretsDir 'home-gateway.key') -Raw).Trim()
$clientPrivateKey = (Get-Content (Join-Path $secretsDir 'client-laptop.key') -Raw).Trim()
$presharedKey = (Get-Content (Join-Path $secretsDir 'preshared.key') -Raw).Trim()
$serverPublicKey = ($serverPrivateKey | & $wg pubkey).Trim()
$clientPublicKey = ($clientPrivateKey | & $wg pubkey).Trim()

$clientAllowedIPs = '10.70.0.0/24'
if ($IncludeHomeLanRoute.IsPresent -and $HomeLanCidr) {
    $clientAllowedIPs = "$clientAllowedIPs, $HomeLanCidr"
}

New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$serverConfig = @"
[Interface]
Address = $ServerAddress
ListenPort = $ListenPort
PrivateKey = $serverPrivateKey

[Peer]
PublicKey = $clientPublicKey
PresharedKey = $presharedKey
AllowedIPs = $ClientAddress
"@

$clientConfig = @"
[Interface]
Address = $ClientAddress
PrivateKey = $clientPrivateKey

[Peer]
PublicKey = $serverPublicKey
PresharedKey = $presharedKey
Endpoint = ${EndpointHost}:$ListenPort
AllowedIPs = $clientAllowedIPs
PersistentKeepalive = 25
"@

$serverPath = Join-Path $generatedDir 'direct-server.conf'
$clientPath = Join-Path $generatedDir 'direct-client-laptop.conf'
$summaryPath = Join-Path $generatedDir 'direct-summary.txt'

[System.IO.File]::WriteAllText($serverPath, $serverConfig)
[System.IO.File]::WriteAllText($clientPath, $clientConfig)

$summary = @"
Direct Windows WireGuard configs rendered.

Server public key: $serverPublicKey
Client public key: $clientPublicKey
Endpoint host: $EndpointHost
Listen port: $ListenPort
Client AllowedIPs: $clientAllowedIPs

Generated files:
- $serverPath
- $clientPath

Next steps:
1. Install the server tunnel service:
   wireguard.exe /installtunnelservice direct-server.conf
2. Import direct-client-laptop.conf on the remote client.
3. If testing on the same LAN, keep EndpointHost as the server LAN IP.
4. If testing remotely, port-forward UDP $ListenPort to the Windows server and use your public IP or DDNS name.
"@
[System.IO.File]::WriteAllText($summaryPath, $summary)

Write-Host "Rendered: $serverPath"
Write-Host "Rendered: $clientPath"
Write-Host "Wrote:    $summaryPath"
