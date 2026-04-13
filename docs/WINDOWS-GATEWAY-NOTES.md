# Windows Gateway Notes

Use this only after the primary tunnel works on the Windows server.

## Scope

A Windows server can be an always-on WireGuard peer. Using it as a LAN gateway for other devices is possible, but it is more awkward than Linux.

## Practical recommendation

Do this in phases:
1. make the Windows box a stable WireGuard peer first
2. verify remote access to the Windows box itself
3. only then add routing/NAT for the rest of the LAN if you really need it

## Why it is trickier on Windows

- forwarding and NAT are less straightforward than on Linux
- service behavior is more opaque
- route persistence can be less obvious
- debugging is usually slower

## If you later want LAN routing through the Windows server

Typical pieces are:
- IP forwarding enabled on the relevant interfaces
- persistent routes on the home router, or NAT on the Windows server
- firewall rules allowing forwarded traffic

## Good first target

Use the Windows server as the always-on peer only. Once that is stable, decide whether to:
- keep it as a host-only peer
- migrate the gateway role to a Linux VM or small dedicated box
- add Windows routing/NAT as a second phase
