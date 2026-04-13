param(
    [Parameter(Mandatory = $true)][string]$ServerPublicKey,
    [string]$PublicHost,
    [string]$HomeLanCidr,
    [string]$HomeGatewayAddress = '10.70.0.2/32',
    [string]$ClientAddress = '10.70.0.10/32',
    [string]$ClientDns = '10.70.0.1'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$secretsDir = Join-Path $root 'secrets'
$generatedDir = Join-Path $root 'generated'
$envFile = Join-Path $root '.env'

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(?<key>[^#=]+)=(?<value>.*)$') {
            Set-Variable -Name $matches['key'] -Value $matches['value'] -Scope Script
        }
    }
}

if (-not $PublicHost) {
    if ($script:PUBLIC_HOST) { $PublicHost = $script:PUBLIC_HOST } else { $PublicHost = 'vpn.example.com' }
}
if (-not $HomeLanCidr) {
    if ($script:HOME_LAN_CIDR) { $HomeLanCidr = $script:HOME_LAN_CIDR } else { $HomeLanCidr = '192.168.50.0/24' }
}

$homeGatewayPrivateKey = (Get-Content (Join-Path $secretsDir 'home-gateway.key') -Raw).Trim()
$clientPrivateKey = (Get-Content (Join-Path $secretsDir 'client-laptop.key') -Raw).Trim()
$presharedKey = (Get-Content (Join-Path $secretsDir 'preshared.key') -Raw).Trim()

New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$homeGatewayConfig = @"
[Interface]
Address = $HomeGatewayAddress
PrivateKey = $homeGatewayPrivateKey
ListenPort = 51820

[Peer]
PublicKey = $ServerPublicKey
PresharedKey = $presharedKey
Endpoint = $PublicHost:51820
AllowedIPs = 10.70.0.0/24
PersistentKeepalive = 25
"@

$clientConfig = @"
[Interface]
Address = $ClientAddress
PrivateKey = $clientPrivateKey
DNS = $ClientDns

[Peer]
PublicKey = $ServerPublicKey
PresharedKey = $presharedKey
Endpoint = $PublicHost:51820
AllowedIPs = 10.70.0.0/24, $HomeLanCidr
PersistentKeepalive = 25
"@

$homeGatewayPath = Join-Path $generatedDir 'home-gateway.wg0.conf'
$clientPath = Join-Path $generatedDir 'client-laptop.conf'

[System.IO.File]::WriteAllText($homeGatewayPath, $homeGatewayConfig)
[System.IO.File]::WriteAllText($clientPath, $clientConfig)

Write-Host "Rendered: $homeGatewayPath"
Write-Host "Rendered: $clientPath"
