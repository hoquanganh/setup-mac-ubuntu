# Master AI Agent Guidelines & Execution Index

This repository contains an end-to-end automated server setup framework designed to transform any computer running Ubuntu (Intel/AMD x86_64, MacBook T2, Laptops, NUCs, VPS) into a 24/7 Home Server hosting multiple projects.

## 🤖 Agent Execution Rules

When an AI Agent (Antigravity, Gemini CLI, Cursor, Claude Code, etc.) is asked to set up or manage this home server, the Agent **MUST** follow these rules:

1. **Non-Interactive First**: Always invoke setup scripts with `--auto` or `DEBIAN_FRONTEND=noninteractive` to prevent hanging on interactive prompts.
2. **Read Applicable Skills**: Before making changes or running setup, read the relevant skill files in `.agent/skills/`.
3. **Execute via Master Script**: Use `./bin/setup.sh --auto` as the primary entry point for complete end-to-end provisioning.
4. **Idempotence**: All scripts in this repo are idempotent. You can rerun `./bin/setup.sh` safely at any time.

## 📚 Agent Skills Index

| Skill File | Purpose | When to Read |
|---|---|---|
| [System Setup Skill](file://.agent/skills/system_setup/SKILL.md) | Hardware detection, T2 driver installation, power & lid sleep management | Fresh Ubuntu setup, hardware driver issues |
| [Server Infrastructure Skill](file://.agent/skills/server_infrastructure/SKILL.md) | PostgreSQL, Redis, MySQL, MongoDB, Node.js, Ruby, Docker, Nginx, UFW | Installing or troubleshooting database/runtime daemons |
| [Remote Access Skill](file://.agent/skills/remote_access/SKILL.md) | Avahi mDNS (`.local`), OpenSSH, Tailscale VPN, ngrok, Cloudflare Tunnels | Setting up or debugging local & remote connectivity |
| [Multi-Project Hosting Skill](file://.agent/skills/multi_project_hosting/SKILL.md) | Nginx VirtualHosts, reverse proxies, multi-app path/domain routing | Adding a new project to host on this server |
| [VN-MDM Live Server Setup Skill](file://.agent/skills/vn_mdm_server_setup/SKILL.md) | Deploying & configuring VN-MDM for real iOS/macOS device enrollment (APNs, ADE, ABM, ngrok HTTPS) | Setting up or debugging real device MDM enrollment & APNs push |

## 🚀 End-to-End One-Command Agent Setup

To provision a fresh server from zero to hosting:

```bash
sudo ./bin/setup.sh --auto
```

Or for a specific hardware profile:
```bash
sudo ./bin/setup.sh --auto --hardware=t2-mac      # Apple MacBook T2 (2018-2020)
sudo ./bin/setup.sh --auto --hardware=laptop      # Generic Laptop (lid sleep fix)
sudo ./bin/setup.sh --auto --hardware=generic-pc  # Desktop PC / NUC / VPS
```
