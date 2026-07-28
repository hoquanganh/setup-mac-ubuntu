---
name: Remote Access & Network Tunneling
description: Automated setup and verification for local mDNS (.local), OpenSSH, Tailscale VPN mesh, and public HTTP tunneling (ngrok / Cloudflare Tunnels). Read before configuring remote access.
---

# Agent Skill: Remote Access & Network Tunneling

## Purpose
Guide the AI Agent to configure multi-layer access so the home server is securely reachable inside local Wi-Fi networks (LAN) and externally across the Internet (WAN).

## Access Layer Matrix
| Access Type | Protocol / Utility | Access Vector | Configuration Step |
|---|---|---|---|
| **Local mDNS** | Avahi Daemon | `http://<hostname>.local` / `ssh user@<hostname>.local` | `sudo systemctl enable --now avahi-daemon` |
| **Private VPN Mesh** | Tailscale | Virtual IP `100.x.y.z` | `sudo tailscale up` |
| **Public HTTPS Tunnel** | ngrok / Cloudflare | Public URL (`https://xxx.ngrok-free.app`) | `ngrok http 80` or `cloudflared tunnel` |

## Agent Verification Protocol
1. Verify mDNS active: `systemctl status avahi-daemon`
2. Verify SSH daemon: `systemctl status ssh`
3. Verify Tailscale status: `tailscale status` or `tailscale ip -4`
4. Test local response: `curl -I http://localhost:80`
