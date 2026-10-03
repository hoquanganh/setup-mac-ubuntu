#!/bin/bash
###############################################################################
# Core Module 05: Remote Access Tools (Avahi mDNS, Tailscale, ngrok, DevOps tools)
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[CORE-05]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Setting up Avahi Daemon for mDNS (.local resolution)..."
apt install -y avahi-daemon
systemctl enable --now avahi-daemon

log "Installing OpenSSH Server..."
apt install -y openssh-server
systemctl enable --now ssh

log "Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
else
  apt install -y tailscale || true
fi

log "Installing ngrok..."
if ! command -v ngrok &>/dev/null; then
  if [ ! -f /etc/apt/sources.list.d/ngrok.list ]; then
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | gpg --dearmor | tee /etc/apt/trusted.gpg.d/ngrok.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com bookworm main" \
      | tee /etc/apt/sources.list.d/ngrok.list
    apt update
  fi
  apt install -y ngrok
fi

log "Installing GitHub CLI (gh) & Azure CLI..."
apt install -y gh || true
if ! command -v az &>/dev/null; then
  curl -sLS https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | tee /usr/share/keyrings/microsoft.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
    | tee /etc/apt/sources.list.d/azure-cli.list
  apt update
  apt install -y azure-cli || true
fi

log "Remote access tools installation complete."
