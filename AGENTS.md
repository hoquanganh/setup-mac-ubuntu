# Master AI Agent Guidelines & Multi-Machine Decision Matrix

This repository is an automated setup framework and cross-machine knowledge base designed to set up, manage, and troubleshoot multiple types of computers and operating systems (Ubuntu Linux, macOS, Apple T2 MacBooks, Lenovo Desktops, Laptops, Cloud VPS).

## 🤖 AI Agent Execution Rules

When an AI Agent (Antigravity, Cursor, Claude Code, Gemini CLI, etc.) is asked to set up or manage any machine using this repository, the Agent **MUST** follow these rules:

1. **Non-Interactive First**: Always invoke setup scripts with `--auto` or `DEBIAN_FRONTEND=noninteractive` to prevent hanging on interactive prompts.
2. **Context & Hardware Detection**: Detect the target platform and machine type before executing commands (see Decision Matrix below).
3. **Safe Execution**: On a live running server, **NEVER** run destructive commands or restart services unless explicitly instructed by the user. Keep existing configurations intact.
4. **Idempotence**: All scripts in this repo are idempotent and safe to run multiple times.

---

## 🧭 Multi-Machine Decision Matrix for AI Agents

When a user asks to set up a machine, consult this matrix to pick the right command and runbook:

| Machine Context / User Prompt | Target Platform | Hardware Profile | Recommended Command | Machine Runbook |
|---|---|---|---|---|
| **Restore this machine (MacBook Pro 2019 Ubuntu)** | Ubuntu | `t2-mac` | `sudo ./bin/restore_current_machine.sh` | [`macbook_pro_2019_ubuntu_server.md`](file://docs/machines/macbook_pro_2019_ubuntu_server.md) |
| **Lenovo ThinkCentre M910q (Dev + VN-MDM)** | Ubuntu | `desktop-lenovo-m910q` | `sudo ./bin/setup.sh --hardware=desktop-lenovo-m910q --profile=dev-workstation --app=vn-mdm --app-mode=native` | [`lenovo_desktop_ubuntu_dev_vnmdm.md`](file://docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md) |
| **MacBook reinstalled with macOS for Rails** | macOS | `auto` | `./bin/setup.sh --platform=macos --profile=dev-workstation` | [`macbook_macos_rails_setup.md`](file://docs/machines/macbook_macos_rails_setup.md) |
| **Generic Laptop 24/7 Home Server** | Ubuntu | `laptop` | `sudo ./bin/setup.sh --hardware=laptop --auto` | [`docs/server/multi_project_hosting.md`](file://docs/server/multi_project_hosting.md) |
| **Generic PC / NUC / VPS** | Ubuntu | `generic-pc` | `sudo ./bin/setup.sh --hardware=generic-pc --auto` | [`docs/QUICKSTART.md`](file://docs/QUICKSTART.md) |

---

## 📚 Agent Skills Index

| Skill File | Purpose | When to Read |
|---|---|---|
| [System Setup Skill](file://.agent/skills/system_setup/SKILL.md) | Hardware detection, T2 driver installation, power & lid sleep management | Fresh Ubuntu setup, hardware driver issues |
| [Server Infrastructure Skill](file://.agent/skills/server_infrastructure/SKILL.md) | PostgreSQL, Redis, MySQL, MongoDB, Node.js, Ruby, Docker, Nginx, UFW | Installing or troubleshooting database/runtime daemons |
| [Remote Access Skill](file://.agent/skills/remote_access/SKILL.md) | Avahi mDNS (`.local`), OpenSSH, Tailscale VPN, ngrok, Cloudflare Tunnels | Setting up or debugging local & remote connectivity |
| [Multi-Project Hosting Skill](file://.agent/skills/multi_project_hosting/SKILL.md) | Nginx VirtualHosts, reverse proxies, multi-app path/domain routing | Adding a new project to host on this server |
| [VN-MDM Live Server Setup Skill](file://.agent/skills/vn_mdm_server_setup/SKILL.md) | Deploying & configuring VN-MDM for real iOS/macOS device enrollment (APNs, ADE, ABM, ngrok HTTPS) | Setting up or debugging real device MDM enrollment & APNs push |
| [Developer Workstation Skill](file://.agent/skills/dev_workstation_setup/SKILL.md) | Setting up full-stack Ubuntu developer workstations (GUI apps, k8s, azure) | When configuring developer desktops or laptops |
| [macOS Rails Setup Skill](file://.agent/skills/macos_rails_setup/SKILL.md) | Setting up macOS for Rails, Homebrew, and resolving native gem compile errors | When working on macOS or troubleshooting gem errors |

---

## 💡 Cross-Platform Reference & Troubleshooting

When troubleshooting across environments:
- For native gem compilation errors (`nokogiri`, `pg`, `libvips`, `openssl`), read [`docs/platform-guides/rails_troubleshooting_cross_platform.md`](file://docs/platform-guides/rails_troubleshooting_cross_platform.md).
- For Ubuntu development apps (TablePlus AppImage, Warp, Cursor, Azure AKS), read [`docs/platform-guides/ubuntu_dev_guide.md`](file://docs/platform-guides/ubuntu_dev_guide.md).
- For macOS background services and OrbStack/Docker, read [`docs/platform-guides/macos_dev_guide.md`](file://docs/platform-guides/macos_dev_guide.md).
