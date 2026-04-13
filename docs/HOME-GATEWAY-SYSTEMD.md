# Home Gateway systemd Notes

Files:
- `systemd/home-gateway/wg-primary.service`
- `systemd/home-gateway/wg-secondary.service`
- `systemd/home-gateway/99-home-gateway-forwarding.conf`

## Purpose

These files are example units for keeping the home gateway tunnels up across reboots.

## Install primary tunnel service

```bash
sudo cp systemd/home-gateway/wg-primary.service /etc/systemd/system/
sudo cp systemd/home-gateway/99-home-gateway-forwarding.conf /etc/sysctl.d/
sudo systemctl daemon-reload
sudo sysctl --system
sudo systemctl enable --now wg-primary.service
```

This assumes the primary tunnel config lives at:
- `/etc/wireguard/wg0.conf`

## Install secondary tunnel service

```bash
sudo cp systemd/home-gateway/wg-secondary.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now wg-secondary.service
```

This assumes the secondary tunnel config lives at:
- `/etc/wireguard/wg-fallback.conf`

## Notes

- These are example units, not distro-specific packages.
- If your distro already uses `wg-quick@wg0` and `wg-quick@wg-fallback`, you can use those directly instead of these custom units.
- Verify interface names and config paths before enabling them on a live host.
