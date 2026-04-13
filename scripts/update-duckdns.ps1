param(
    [string]$Subdomain = $env:DUCKDNS_SUBDOMAIN,
    [string]$Token = $env:DUCKDNS_TOKEN,
    [string]$Ipv4
)

$ErrorActionPreference = 'Stop'

if (-not $Subdomain) {
    throw 'Missing DuckDNS subdomain. Pass -Subdomain or set DUCKDNS_SUBDOMAIN.'
}
if (-not $Token) {
    throw 'Missing DuckDNS token. Pass -Token or set DUCKDNS_TOKEN.'
}
if (-not $Ipv4) {
    $Ipv4 = (Invoke-RestMethod 'https://api.ipify.org').ToString().Trim()
}

$url = "https://www.duckdns.org/update?domains=$Subdomain&token=$Token&ip=$Ipv4"
$response = (Invoke-RestMethod $url).ToString().Trim()

Write-Host "DuckDNS response: $response"
Write-Host "Subdomain:        $Subdomain.duckdns.org"
Write-Host "IPv4:             $Ipv4"

if ($response -ne 'OK') {
    throw "DuckDNS update failed: $response"
}
