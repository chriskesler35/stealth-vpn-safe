# Router Static Routes

Once the primary relay path is stable, a static route on the home router is usually cleaner than long-term NAT on the home gateway.

## Goal

Tell the home router that the VPN overlay networks live behind the home gateway.

Example:
- home gateway LAN IP: `192.168.50.10`
- primary overlay: `10.70.0.0/24`
- fallback overlay: `10.71.0.0/24`

Add routes on the home router:
- destination `10.70.0.0/24` via `192.168.50.10`
- destination `10.71.0.0/24` via `192.168.50.10`

## Why this is better

- avoids unnecessary NAT between the VPN overlay and your LAN
- makes return traffic predictable
- simplifies debugging
- preserves original client IPs better inside the LAN

## UniFi

Path varies by controller version, but the usual pattern is:
- Settings
- Routing
- Static Routes
- Add Route

Example values:
- Name: `VPN Overlay Primary`
- Destination Network: `10.70.0.0/24`
- Type: `Next Hop`
- Next Hop: `192.168.50.10`

Repeat for:
- Name: `VPN Overlay Fallback`
- Destination Network: `10.71.0.0/24`
- Next Hop: `192.168.50.10`

## pfSense

Path:
- System
- Routing
- Static Routes
- Add

Example values:
- Destination network: `10.70.0.0/24`
- Gateway: a gateway object pointing to the home gateway IP on your LAN

Repeat for `10.71.0.0/24`.

You may also want a firewall rule on the LAN interface permitting traffic between the LAN and those overlay subnets.

## OpenWrt

In LuCI:
- Network
- Routing
- Static IPv4 Routes
- Add

Example values:
- Interface: `lan`
- Target: `10.70.0.0/24`
- IPv4-Gateway: `192.168.50.10`

Repeat for `10.71.0.0/24`.

## Generic Consumer Routers

If the router supports static routes, look for:
- Advanced Routing
- Static Routing
- LAN Routing

If it does not support static routes cleanly, keep NAT enabled on the home gateway for now.

## Verification

From a LAN host:
- ping `10.70.0.1`
- ping `10.70.0.10`
- ping `10.71.0.1` if the fallback path is enabled

From a remote VPN client:
- ping a normal LAN host
- access one internal service directly by IP

## Rollout Advice

- start with NAT while you get the tunnel working
- move to static routes once connectivity is stable
- change one thing at a time so you know what broke if something fails
