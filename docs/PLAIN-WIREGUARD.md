# Plain WireGuard Relay Option

If you want a more declarative deployment than `wg-easy`, use this path.

Files:
- `docker-compose.wireguard-core.yml`
- `config/server-wg0.conf.example`
- `scripts/render-server-config.sh`

## Why switch

- file-based config instead of UI-managed peers
- easier to review and back up in infrastructure workflows
- less moving UI state

## Tradeoffs

- more manual key and peer management
- less convenient onboarding than `wg-easy`

## Workflow

1. Run the normal bootstrap:

```bash
./scripts/bootstrap-linux.sh
```

2. Generate a VPS private key on the relay host:

```bash
wg genkey | tee server.key | wg pubkey
```

3. Render the server config locally:

```bash
./scripts/render-server-config.sh --server-private-key-file ./server.key
```

4. On the relay host, create the expected config directory and copy the rendered file into it:

```bash
mkdir -p wireguard-core/wg_confs
cp generated/server-wg0.conf wireguard-core/wg_confs/wg0.conf
```

5. Start the plain WireGuard stack:

```bash
docker compose -f docker-compose.wireguard-core.yml up -d
```

## Notes

- This compose file mounts `./wireguard-core` to `/config`, so the config lands at `wireguard-core/wg_confs/wg0.conf` on the host.
- I have not run this exact container path in your environment, so do a quick smoke test after bringing it up and adjust if the image revision expects a slightly different layout.
