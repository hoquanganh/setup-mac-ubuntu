---
name: Developer Workstation Setup (Ubuntu & Linux)
description: Automated setup of developer workstations on Ubuntu 24.04/26.04 including base tools, zsh, vim, Chrome, Cursor, Warp, TablePlus, Docker, Kubernetes, Azure CLI, and Ruby/Node runtimes.
---

# Developer Workstation Setup Skill

This skill guides the AI Agent when a user wants to configure a fresh Ubuntu installation (like on a Lenovo Desktop or developer laptop) for full-stack software development.

## 🎯 When to Use This Skill
- The user requests setting up a developer PC, workstation, or laptop on Ubuntu Linux.
- The user mentions developer tools: zsh, vim, Google Chrome, Cursor IDE, Warp terminal, TablePlus, Vietnamese typing (`ibus-bamboo`), or Kubernetes/Azure CLI.
- Reference machine runbook: [`docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md`](file:///home/qa/Documents/Ubuntu_install/docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md).

## 🚀 Execution Commands

To execute the automated workstation pipeline:
```bash
sudo ./bin/setup.sh --profile=dev-workstation --auto
```

Or run the modular workstation script directly:
```bash
sudo bash platforms/ubuntu/setup_dev_machine.sh
```

## 📚 Key Reference Points
- **TablePlus on Ubuntu 24.04+**: TablePlus does not have an apt repo for noble; it is installed as an AppImage in `~/Documents/Systems/install-packs/` with a desktop entry at `~/.local/share/applications/tableplus.desktop`.
- **Azure CLI & Kubernetes**: Installed via official Microsoft repositories with `kubelogin` and `stern` via Krew.
- **Vietnamese Typing**: Installed via PPA `ppa:bamboo-engine/ibus-bamboo`.
