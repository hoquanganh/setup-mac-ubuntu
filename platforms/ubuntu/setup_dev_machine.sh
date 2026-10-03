#!/bin/bash
###############################################################################
# Ubuntu Developer Workstation Setup Script
# Configures a fresh Ubuntu installation for full-stack software development:
# - Base compilers, build tools, zsh, vim
# - Programming runtimes: Ruby (rbenv), Node.js, Docker
# - Databases: PostgreSQL, Redis (and optional MySQL, MongoDB)
# - Cloud & K8s tooling: Azure CLI, kubectl, kubelogin, stern
# - Desktop apps: Chrome, Cursor, Warp, TablePlus, Vietnamese typing
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\n\033[1;32m[UBUNTU-DEV-SETUP]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

log "Starting Ubuntu Developer Workstation Provisioning for user: $REAL_USER..."

# 1. Base System
log "Step 1/6: Installing base system tools, zsh, vim, build tools..."
bash "$SCRIPT_DIR/base/install_base.sh"

# 2. Databases
log "Step 2/6: Installing development databases (PostgreSQL, Redis, MySQL, MongoDB)..."
bash "$SCRIPT_DIR/databases/install_databases.sh"

# 3. Programming Runtimes
log "Step 3/6: Installing runtimes (Node.js, Ruby via rbenv, Docker)..."
bash "$SCRIPT_DIR/runtimes/install_runtimes.sh"

# 4. Kubernetes & Cloud CLI Tools
log "Step 4/6: Installing Kubernetes & Azure CLI dev tools..."
# Azure CLI
if ! command -v az &>/dev/null; then
  log "Installing Azure CLI..."
  apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg --yes 2>/dev/null || true
  UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/azure-cli.list
  apt update && apt install -y azure-cli || warn "Azure CLI apt repository unavailable, skipping."
fi

# kubectl
if ! command -v kubectl &>/dev/null; then
  log "Installing kubectl..."
  KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "v1.30.0")
  curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
  chmod +x /usr/local/bin/kubectl
fi

# kubelogin
if ! command -v kubelogin &>/dev/null; then
  log "Installing kubelogin (Azure)..."
  TMP_DIR=$(mktemp -d)
  wget -q -O "$TMP_DIR/kubelogin.zip" https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip || true
  if [ -f "$TMP_DIR/kubelogin.zip" ]; then
    unzip -q -o "$TMP_DIR/kubelogin.zip" -d "$TMP_DIR"
    mv "$TMP_DIR/bin/linux_amd64/kubelogin" /usr/local/bin/kubelogin || true
    chmod +x /usr/local/bin/kubelogin || true
  fi
  rm -rf "$TMP_DIR"
fi

# 5. Desktop GUI Applications (Optional if display detected)
if [ -n "$DISPLAY" ] || [ -d "/usr/share/xsessions" ] || [ -d "/usr/share/wayland-sessions" ]; then
  log "Step 5/6: Desktop environment detected. Installing GUI apps..."
  bash "$SCRIPT_DIR/desktop-apps/install_desktop_apps.sh"
else
  log "Step 5/6: Headless server environment detected. Skipping GUI desktop apps."
fi

# 6. Remote Access & Local Domain
log "Step 6/6: Configuring Avahi mDNS and SSH..."
bash "$SCRIPT_DIR/services/install_remote_access.sh"

log "=========================================================="
log " 🎉 UBUNTU DEV WORKSTATION SETUP COMPLETE!"
log "=========================================================="
log " Next steps for developer:"
log " 1. Set Zsh as default shell: chsh -s $(which zsh) $REAL_USER"
log " 2. Log in with GitHub CLI:  gh auth login"
log " 3. Verify Docker:           docker ps (without sudo)"
log " 4. Verify Ruby:             ruby -v (managed by rbenv)"
log " 5. Verify Node:             node -v"
log "=========================================================="
