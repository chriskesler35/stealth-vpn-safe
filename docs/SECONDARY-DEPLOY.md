# Secondary VPS Deploy Guide

This guide assumes:
- the primary VPS path already works
- you now want a dedicated fallback VPS
- the fallback VPS will run both the secondary WireGuard path and OpenVPN TCP 443

## 1. Generate a private key for the secondary VPS

```bash
wg genkey | tee secondary-server.key | wg pubkey
```

## 2. Render the fallback WireGuard configs

```bash
./scripts/render-secondary-path-configs.sh --server-private-key-file ./secondary-server.key
```

This writes:
- `generated/server-secondary-wg0.conf`
- `generated/home-gateway-secondary.wg0.conf`

## 3. Prepare the fallback VPS

On the fallback VPS, create the expected WireGuard config path:

```bash
mkdir -p wireguard-secondary/wg_confs
```

Copy the rendered config there:

```bash
cp generated/server-secondary-wg0.conf wireguard-secondary/wg_confs/wg0.conf
```

## 4. Initialize OpenVPN on the fallback VPS

```bash
FALLBACK_HOST=fallback.example.com HOME_LAN_CIDR=192.168.50.0/24 ./scripts/init-openvpn.sh
```

That creates the base OpenVPN server config in `openvpn/`.

Initialize the PKI:

```bash
docker run -it --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_initpki
```

## 5. Start the fallback VPS stack

```bash
docker compose -f docker-compose.secondary-relay.yml up -d
```

## 6. Install the fallback tunnel on the home gateway

Copy the rendered config onto the home gateway:

```bash
sudo cp generated/home-gateway-secondary.wg0.conf /etc/wireguard/wg-fallback.conf
```

Install the systemd unit examples if you want persistent startup:

```bash
sudo cp systemd/home-gateway/wg-secondary.service /etc/systemd/system/
sudo cp systemd/home-gateway/99-home-gateway-forwarding.conf /etc/sysctl.d/
sudo systemctl daemon-reload
sudo sysctl --system
sudo systemctl enable --now wg-secondary.service
```

## 7. Export an OpenVPN client profile

```bash
docker run -it --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 easyrsa build-client-full laptop nopass
docker run --rm -v "$PWD/openvpn:/etc/openvpn" kylemanna/openvpn:2.6 ovpn_getclient laptop > generated/client-laptop.ovpn
```

## 8. Validate the fallback path

```bash
./scripts/check-relays.sh
```

Then connect with the OpenVPN client and verify access to the home gateway and a LAN host.

## Notes

- This fallback host should ideally be a different provider or region than the primary.
- Keep the fallback path simple: remote access only, not public app publishing.
- If both the primary and fallback WireGuard tunnels are live on the home gateway, be deliberate with routes so you avoid asymmetric return paths.
