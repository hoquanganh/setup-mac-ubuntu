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

# 6. Suppress Wi-Fi PCIe AER log storms & configure journald / log rotation limits
log "Configuring log protection (PCIe AER suppression & journald limits)..."

# Suppress Intel 7265 PCIe correctable bus errors in rsyslog
mkdir -p /etc/rsyslog.d
cat <<'EOF' > /etc/rsyslog.d/10-suppress-pcie-aer.conf
# Suppress PCIe AER correctable errors from Intel 7265 Wi-Fi root port (00:1c.0)
:msg, contains, "PCIe Bus Error" stop
:msg, contains, "AER: Correctable error message" stop
:msg, contains, "RxErr" stop
EOF
systemctl restart rsyslog 2>/dev/null || true

# Limit systemd journal disk usage
mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' > /etc/systemd/journald.conf.d/00-size-limit.conf
[Journal]
SystemMaxUse=1G
RuntimeMaxUse=200M
EOF
systemctl restart systemd-journald 2>/dev/null || true

# Configure MongoDB logrotate if mongodb is present
if [ -d /var/log/mongodb ]; then
  cat <<'EOF' > /etc/logrotate.d/mongodb
/var/log/mongodb/*.log {
    weekly
    maxsize 100M
    rotate 4
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF
fi

# Add pci=noaer to GRUB if not present
if [ -f /etc/default/grub ] && ! grep -q "pci=noaer" /etc/default/grub; then
  log "Adding pci=noaer to GRUB kernel parameters to permanently suppress PCIe AER noise..."
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="pci=noaer /' /etc/default/grub
  update-grub 2>/dev/null || true
fi

log "Desktop hardware optimization complete."

