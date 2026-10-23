#!/bin/bash
###############################################################################
# Lenovo ThinkCentre M910q / Generic Desktop PC Hardware Optimization Script
# Support: Ubuntu 22.04 / 24.04 / 26.04
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[HARDWARE-M910Q]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Configuring Lenovo ThinkCentre M910q / Generic PC hardware profile..."

# 1. Disable Sleep / Suspend if this desktop is intended to stay awake as server/dev machine
KEEPALIVE_CONF="/etc/systemd/logind.conf.d/desktop-keepalive.conf"
if [ ! -f "$KEEPALIVE_CONF" ]; then
  log "Configuring systemd power management to keep desktop awake..."
  mkdir -p /etc/systemd/logind.conf.d/
  cat <<EOF > "$KEEPALIVE_CONF"
[Login]
IdleAction=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
EOF
else
  log "Keep-alive configuration already present at $KEEPALIVE_CONF."
fi

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

# 5. Disable Wi-Fi Power Save & Install Watchdog Failover Service
log "Configuring Wi-Fi power management & watchdog..."
mkdir -p /etc/NetworkManager/conf.d/
cat <<EOF > /etc/NetworkManager/conf.d/99-disable-wifi-powersave.conf
[connection]
wifi.powersave = 2
EOF
if [ -f /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf ]; then
  sed -i "s/wifi.powersave = 3/wifi.powersave = 2/g" /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf 2>/dev/null || true
fi
systemctl reload NetworkManager 2>/dev/null || true

# Turn off power management on current Wi-Fi interface if present
if command -v iwconfig &>/dev/null; then
  iwconfig wlp2s0 power off 2>/dev/null || true
fi

# Install and enable wifi-failover-watchdog
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCHDOG_SVC="$SCRIPT_DIR/services/wifi-failover-watchdog.service"
WATCHDOG_TIMER="$SCRIPT_DIR/services/wifi-failover-watchdog.timer"
if [ -f "$WATCHDOG_SVC" ] && [ -f "$WATCHDOG_TIMER" ]; then
  cp "$WATCHDOG_SVC" "$WATCHDOG_TIMER" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now wifi-failover-watchdog.timer 2>/dev/null || true
  log "Enabled wifi-failover-watchdog.timer."
fi

log "Desktop hardware optimization complete."
