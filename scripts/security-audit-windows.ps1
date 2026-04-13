$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Title)
    Write-Host "`n=== $Title ==="
}

function Try-Run {
    param(
        [string]$Label,
        [scriptblock]$Block
    )

    Write-Host "-- $Label --"
    try {
        & $Block
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)"
    }
}

Write-Section 'System'
Try-Run 'OS version' {
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
}
Try-Run 'Current IPv4 addresses' {
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize
}
Try-Run 'Routes' {
    route print
}

Write-Section 'WireGuard'
Try-Run 'WireGuard version' {
    & 'C:\Program Files\WireGuard\wg.exe' --version
}
Try-Run 'WireGuard state' {
    & 'C:\Program Files\WireGuard\wg.exe' show
}
Try-Run 'WireGuard services' {
    Get-CimInstance Win32_Service | Where-Object { $_.Name -like 'WireGuardTunnel$*' -or $_.Name -like 'WireGuardManager*' } | Select-Object Name, State, StartMode, DisplayName | Format-Table -AutoSize
}

Write-Section 'Exposure'
Try-Run 'Listening TCP ports' {
    Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
}
Try-Run 'Listening UDP endpoints' {
    Get-NetUDPEndpoint | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
}
Try-Run 'Remote Desktop firewall rules' {
    Get-NetFirewallRule -DisplayGroup 'Remote Desktop' | Select-Object DisplayName, Enabled, Direction, Action, Profile | Format-Table -AutoSize
}
Try-Run 'Custom WireGuard RDP rules' {
    Get-NetFirewallRule | Where-Object { $_.DisplayName -like 'RDP from WireGuard*' } | Select-Object DisplayName, Enabled, Direction, Action, Profile | Format-Table -AutoSize
}
Try-Run 'WireGuard UDP firewall rule' {
    Get-NetFirewallRule -DisplayName 'WireGuard UDP 51820' | Select-Object DisplayName, Enabled, Direction, Action, Profile | Format-Table -AutoSize
}

Write-Section 'RDP'
Try-Run 'RDP enabled registry flag' {
    Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' | Select-Object fDenyTSConnections
}
Try-Run 'NLA required' {
    Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' | Select-Object UserAuthentication, SecurityLayer
}
Try-Run 'TermService status' {
    Get-Service -Name TermService | Select-Object Name, Status, StartType
}

Write-Section 'Platform hardening'
Try-Run 'BitLocker volumes' {
    Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod | Format-Table -AutoSize
}
Try-Run 'Windows Defender Firewall profiles' {
    Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
}
Try-Run 'Windows Update service' {
    Get-Service -Name wuauserv | Select-Object Name, Status, StartType
}
Try-Run 'Public IP' {
    (Invoke-RestMethod 'https://api.ipify.org').ToString()
}

Write-Section 'Notes'
Write-Host 'Review goals:'
Write-Host '- only UDP 51820 intentionally exposed for WireGuard'
Write-Host '- no public RDP exposure'
Write-Host '- RDP ideally restricted to 10.70.0.0/24 only'
Write-Host '- WireGuard tunnel service should be Running + Auto'
Write-Host '- BitLocker and Windows Firewall should be enabled'
