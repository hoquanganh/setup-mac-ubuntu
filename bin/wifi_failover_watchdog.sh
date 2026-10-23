#!/bin/bash
###############################################################################
# Wi-Fi Watchdog & Automated Failover Monitor for Lenovo ThinkCentre M910q
# Detects silent link freezes, zombie connections, or gateway/internet loss.
# Automatically fails over between 'QA' and 'FPT Telecom-E971-IOT'.
# Ensures Wi-Fi power saving remains permanently disabled.
###############################################################################
set -u

IFACE="wlp2s0"
PRIMARY_CON="QA"
BACKUP_CON="FPT Telecom-E971-IOT"
CHECK_TARGETS=("8.8.8.8" "1.1.1.1")
LOG_TAG="wifi-watchdog"

log_info() {
  echo "[INFO] $1"
  logger -t "$LOG_TAG" "[INFO] $1"
}

log_warn() {
  echo "[WARN] $1" >&2
  logger -t "$LOG_TAG" "[WARN] $1"
}

log_error() {
  echo "[ERROR] $1" >&2
  logger -t "$LOG_TAG" "[ERROR] $1"
}

# 1. Ensure Wi-Fi power management is always off
if command -v /usr/sbin/iwconfig >/dev/null 2>&1; then
  /usr/sbin/iwconfig "$IFACE" power off 2>/dev/null || true
fi

# 2. Check Internet Connectivity
check_connectivity() {
  for target in "${CHECK_TARGETS[@]}"; do
    if ping -I "$IFACE" -c 1 -W 2 "$target" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

# Quick initial check
if check_connectivity; then
  # Healthy
  exit 0
fi

# If failed, retry 2 times before taking action (prevent false positives)
log_warn "First ping check failed on $IFACE. Verifying in 3 seconds..."
sleep 3
if check_connectivity; then
  log_info "Transient glitch recovered. Network is reachable."
  exit 0
fi

sleep 3
if check_connectivity; then
  log_info "Transient glitch recovered on 2nd retry. Network is reachable."
  exit 0
fi

# 3. Connection is confirmed DOWN. Identify current active connection.
CURRENT_CON=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep ":$IFACE" | cut -d: -f1 || true)
log_warn "Internet drop confirmed on $IFACE (Current active profile: '${CURRENT_CON:-none}')."

# Determine target connection to fail over to
if [ "$CURRENT_CON" = "$PRIMARY_CON" ]; then
  TARGET_CON="$BACKUP_CON"
elif [ "$CURRENT_CON" = "$BACKUP_CON" ]; then
  TARGET_CON="$PRIMARY_CON"
else
  TARGET_CON="$PRIMARY_CON"
fi

log_warn "Initiating failover switch to '$TARGET_CON'..."
nmcli connection up "$TARGET_CON" 2>&1 || true
sleep 4

# Re-disable power save on new connection
if command -v /usr/sbin/iwconfig >/dev/null 2>&1; then
  /usr/sbin/iwconfig "$IFACE" power off 2>/dev/null || true
fi

# Verify if failover restored connectivity
if check_connectivity; then
  log_info "Failover to '$TARGET_CON' successful! Internet connectivity restored."
  exit 0
fi

# 4. If still down after failover, power-cycle the Wi-Fi radio to reset PCIe/MAC state
log_error "Failover to '$TARGET_CON' did not restore connectivity. Resetting Wi-Fi radio..."
nmcli radio wifi off 2>&1 || true
sleep 2
nmcli radio wifi on 2>&1 || true
sleep 4

# Attempt to bring up target connection
if ! nmcli connection up "$TARGET_CON" 2>&1; then
  log_warn "Failed to bring up '$TARGET_CON' after radio restart. Trying '$PRIMARY_CON'..."
  nmcli connection up "$PRIMARY_CON" 2>&1 || true
fi

sleep 3
if command -v /usr/sbin/iwconfig >/dev/null 2>&1; then
  /usr/sbin/iwconfig "$IFACE" power off 2>/dev/null || true
fi

if check_connectivity; then
  log_info "Wi-Fi radio reset restored internet connectivity!"
  exit 0
else
  log_error "Critical: Unable to restore internet connection after failover and radio reset."
  exit 1
fi
