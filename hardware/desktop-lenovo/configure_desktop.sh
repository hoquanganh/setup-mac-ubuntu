#!/bin/bash
###############################################################################
# Lenovo Desktop / Generic PC Hardware Optimization Script
# Support: Ubuntu 22.04 / 24.04 / 26.04
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[HARDWARE-DESKTOP]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Configuring Lenovo Desktop / Generic PC hardware profile..."

# 1. Disable Sleep / Suspend if this desktop is intended to stay awake as server/dev machine
log "Configuring systemd power management to keep desktop awake..."
mkdir -p /etc/systemd/logind.conf.d/
cat <<EOF > /etc/systemd/logind.conf.d/desktop-keepalive.conf
[Login]
IdleAction=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
EOF

# Mask suspend targets to prevent unexpected sleep
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

# 2. Performance Tuning (CPU governor)
log "Checking CPU performance governor tools..."
if ! command -v cpupower &>/dev/null; then
  apt install -y linux-tools-generic linux-tools-common 2>/dev/null || warn "cpupower package not installed."
fi

# 3. Check for recommended GPU / proprietary drivers
log "Checking hardware drivers (NVIDIA / Intel / AMD)..."
if command -v ubuntu-drivers &>/dev/null; then
  ubuntu-drivers devices || true
fi

# 4. Enable Wake-on-LAN support (if wired ethernet is present)
log "Configuring network interfaces for Wake-on-LAN..."
if command -v ethtool &>/dev/null; then
  DEFAULT_IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n 1)
  if [ -n "$DEFAULT_IFACE" ]; then
    ethtool -s "$DEFAULT_IFACE" wol g 2>/dev/null || true
    log "Configured WOL on $DEFAULT_IFACE"
  fi
fi

log "Desktop hardware optimization complete."
