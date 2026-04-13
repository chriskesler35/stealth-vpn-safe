# OpenVPN TCP 443 Fallback

This is the emergency fallback path for networks where WireGuard UDP is unreliable or blocked.

It uses standard OpenVPN over TCP 443. That is slower than WireGuard, but it is widely supported and often survives restrictive guest networks better.

## Important Constraint

On a single-IP VPS, OpenVPN on TCP 443 conflicts with the HTTPS relay in `docker-compose.yml` because both need TCP 443.

Use one of these patterns:
- stop Caddy temporarily and run OpenVPN instead
- attach a second public IP and bind OpenVPN there
- run the OpenVPN stack on a separate small fallback VPS

## Files

- `docker-compose.openvpn.yml`
- `scripts/init-openvpn.sh`
- `docs/FALLBACK-SECONDARY-VPS.md`

## Initialize

```bash
cd stealth-vpn-safe
chmod +x scripts/*.sh
FALLBACK_HOST=fallback.example.com HOME_LAN_CIDR=192.168.50.0/24 ./scripts/init-openvpn.sh
```

That generates the base OpenVPN server config in `openvpn/`.

## Build the PKI

```bash
docker run -it --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_initpki
```

## Start the fallback server

```bash
docker compose -f docker-compose.openvpn.yml up -d
```

## Create a client profile

```bash
docker run -it --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 easyrsa build-client-full laptop nopass
docker run --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_getclient laptop > generated/client-laptop.ovpn
```

## Routing Expectations

The relay host must still be able to reach the home LAN. In this starter architecture, that means the relay's routing toward `192.168.50.0/24` through the home gateway remains in place.

## Suggested Operating Model

- keep WireGuard as primary
- keep OpenVPN stopped until needed
- only activate it during restrictive-network incidents
- prefer the secondary-VPS layout in `docs/FALLBACK-SECONDARY-VPS.md` if you want it always available

## Verification

After importing the `.ovpn` profile on a client:

```bash
ping 10.70.0.2
ping 192.168.50.1
```

If the overlay ping works but the LAN ping does not, the relay-to-home routing path is the first place to inspect.
