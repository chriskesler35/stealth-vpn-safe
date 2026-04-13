# Home Server Quickstart

This guide is the practical path for turning your home server into the home gateway for the relay kit.

Assumptions:
- the home server runs Linux
- it has a stable LAN IP or can be assigned one
- it will act as the always-on home gateway peer
- the public relay VPS will be set up separately

## 1. Install prerequisites

Ubuntu or Debian:

```bash
sudo apt update
sudo apt install -y git make curl wireguard-tools
```

If `wg-quick` is missing after that, install the `wireguard` package too:

```bash
sudo apt install -y wireguard
```

## 2. Clone the repo

If GitHub SSH is already configured:

```bash
git clone git@github.com:chriskesler35/stealth-vpn-safe.git
```

If not, use GitHub CLI auth first:

```bash
gh auth login
git clone https://github.com/chriskesler35/stealth-vpn-safe.git
```

Then enter the repo:

```bash
cd stealth-vpn-safe
```

## 3. Record your real values

Open `docs/DECISIONS.md` and fill in at least:
- Primary host
- Fallback host
- Home LAN CIDR
- Home gateway LAN IP
- Router type
- First published app

## 4. Bootstrap secrets and `.env`

Replace the example values below with your real ones.

```bash
make bootstrap \
  PUBLIC_HOST=vpn.example.com \
  FALLBACK_HOST=fallback.example.com \
  ACME_EMAIL=admin@example.com \
  HOME_LAN_CIDR=192.168.50.0/24
```

This creates:
- `secrets/home-gateway.key`
- `secrets/preshared.key`
- `secrets/fallback-preshared.key`
- `generated/bootstrap-summary.txt`
- `.env`

## 5. Enable forwarding on the home server

```bash
sudo cp systemd/home-gateway/99-home-gateway-forwarding.conf /etc/sysctl.d/
sudo sysctl --system
```

Verify:

```bash
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
```

## 6. Wait for or obtain the primary relay public key

Once the VPS relay is up, get its WireGuard public key on the relay host:

```bash
docker exec relay-wireguard wg show wg0 public-key
```

If you use the plain WireGuard relay instead of `wg-easy`, get the public key from that server config or via `wg show` on the VPS.

## 7. Render the primary home-gateway config

On the home server:

```bash
make render-primary SERVER_PUBLIC_KEY='<paste-relay-public-key>'
```

That writes:
- `generated/home-gateway.wg0.conf`
- `generated/client-laptop.conf`

## 8. Install the primary tunnel

```bash
sudo cp generated/home-gateway.wg0.conf /etc/wireguard/wg0.conf
sudo cp systemd/home-gateway/wg-primary.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now wg-primary.service
```

Check the tunnel:

```bash
sudo wg show
ip addr show wg0
```

## 9. Test reachability

After the VPS side is live, test from the home server:

```bash
ping -c 3 10.70.0.1
```

From a remote client connected through the relay, test:

```bash
ping 10.70.0.2
ping 192.168.50.1
```

## 10. Decide NAT first or static routes first

Fastest path:
- get the tunnel working first
- keep NAT on the home gateway if needed temporarily

Cleaner long-term path:
- add router static routes for `10.70.0.0/24` and later `10.71.0.0/24`
- use `docs/ROUTER-STATIC-ROUTES.md`

## 11. Only after primary is stable, add the fallback path

When the main path works, continue with:
- `docs/SECONDARY-DEPLOY.md`
- `docs/FALLBACK-OPENVPN.md`

## Recommended checkpoint to send back

After steps 1 through 5, send back:
- distro and version: `cat /etc/os-release`
- LAN IPs: `ip -4 addr`
- routes: `ip route`
- whether `wg` exists: `wg --version`
- the contents of `generated/bootstrap-summary.txt` with private key paths left as-is but without pasting secret contents
