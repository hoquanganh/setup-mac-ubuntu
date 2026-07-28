#!/bin/bash
###############################################################################
# Hardware Module: Laptop Power Management (24/7 Uptime)
# Prevents laptop from sleeping when lid is closed.
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[POWER MANAGEMENT]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Configuring systemd logind for lid close behavior..."
LOGIND_CONF="/etc/systemd/logind.conf"

sed -i 's/^#\?HandleLidSwitch=.*/HandleLidSwitch=ignore/' "$LOGIND_CONF"
sed -i 's/^#\?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' "$LOGIND_CONF"
sed -i 's/^#\?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' "$LOGIND_CONF"

log "Masking sleep & hibernate targets to guarantee continuous uptime..."
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

log "Restarting systemd-logind service..."
systemctl restart systemd-logind || true

log "Power management configuration complete. Laptop will stay awake with lid closed."
