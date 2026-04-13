param(
    [Parameter(Mandatory = $true)][string]$PublicHost,
    [Parameter(Mandatory = $true)][string]$FallbackHost,
    [Parameter(Mandatory = $true)][string]$AcmeEmail,
    [Parameter(Mandatory = $true)][string]$HomeLanCidr
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

function Ensure-File {
    param(
        [string]$Path,
        [scriptblock]$Generator
    )

    if (-not (Test-Path $Path)) {
        $value = & $Generator
        [System.IO.File]::WriteAllText($Path, ($value.Trim() + "`n"))
    }
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$secretsDir = Join-Path $root 'secrets'
$generatedDir = Join-Path $root 'generated'
$envExample = Join-Path $root '.env.example'
$envFile = Join-Path $root '.env'
$wg = Get-WgExe

New-Item -ItemType Directory -Force -Path $secretsDir, $generatedDir | Out-Null

Ensure-File -Path (Join-Path $secretsDir 'home-gateway.key') -Generator { & $wg genkey }
Ensure-File -Path (Join-Path $secretsDir 'client-laptop.key') -Generator { & $wg genkey }
Ensure-File -Path (Join-Path $secretsDir 'preshared.key') -Generator { & $wg genpsk }
Ensure-File -Path (Join-Path $secretsDir 'fallback-preshared.key') -Generator { & $wg genpsk }

$homeGatewayPrivateKey = (Get-Content (Join-Path $secretsDir 'home-gateway.key') -Raw).Trim()
$clientPrivateKey = (Get-Content (Join-Path $secretsDir 'client-laptop.key') -Raw).Trim()
$homeGatewayPublicKey = $homeGatewayPrivateKey | & $wg pubkey
$clientPublicKey = $clientPrivateKey | & $wg pubkey

if (-not (Test-Path $envFile)) {
    Copy-Item $envExample $envFile
}

$envLines = Get-Content $envFile
$updates = [ordered]@{
    'PUBLIC_HOST' = $PublicHost
    'FALLBACK_HOST' = $FallbackHost
    'ACME_EMAIL' = $AcmeEmail
    'HOME_LAN_CIDR' = $HomeLanCidr
}

$seen = @{}
$updatedLines = foreach ($line in $envLines) {
    if ($line -match '^(?<key>[^#=]+)=(?<value>.*)$') {
        $key = $matches['key']
        if ($updates.Contains($key)) {
            $seen[$key] = $true
            "{0}={1}" -f $key, $updates[$key]
            continue
        }
    }
    $line
}

foreach ($entry in $updates.GetEnumerator()) {
    if (-not $seen.ContainsKey($entry.Key)) {
        $updatedLines += "{0}={1}" -f $entry.Key, $entry.Value
    }
}

[System.IO.File]::WriteAllLines($envFile, $updatedLines)

$summary = @"
Home-lab relay bootstrap complete.

Generated assets:
- home gateway private key:   $(Join-Path $secretsDir 'home-gateway.key')
- home gateway public key:    $($homeGatewayPublicKey.Trim())
- client private key:         $(Join-Path $secretsDir 'client-laptop.key')
- client public key:          $($clientPublicKey.Trim())
- primary preshared key:      $(Join-Path $secretsDir 'preshared.key')
- fallback preshared key:     $(Join-Path $secretsDir 'fallback-preshared.key')
- env file:                   $envFile

Next steps:
1. Review $envFile and replace any remaining placeholder values.
2. Bring up the primary relay on the VPS.
3. Get the relay public key from the VPS.
4. Render the peer configs with scripts\render-peer-configs.ps1.
"@

$summaryPath = Join-Path $generatedDir 'bootstrap-summary.txt'
[System.IO.File]::WriteAllText($summaryPath, $summary)
Write-Host "Wrote $summaryPath"
