#!/bin/bash
###############################################################################
# Master Universal Server Setup & Provisioning Script
# Support: Ubuntu 22.04 / 24.04 / 26.04
# Hardware support: Apple T2 Mac, Laptop, Generic PC / NUC / VPS
# Mode: Interactive or Fully Automated (--auto)
###############################################################################
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[SERVER-SETUP]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

# Parse CLI help option early
for arg in "$@"; do
  if [ "$arg" == "--help" ]; then
    echo "Usage: sudo ./bin/setup.sh [OPTIONS]"
    echo "Options:"
    echo "  --auto               Run in non-interactive fully automated mode"
    echo "  --hardware=TYPE      Specify hardware profile (auto, t2-mac, laptop, generic-pc)"
    echo "  --skip-app           Skip default app deployment (VN-MDM)"
    exit 0
  fi
done

if [ "$EUID" -ne 0 ]; then
  err "This script must be run with root privileges (sudo)."
  exit 1
fi

HARDWARE_MODE="auto"
AUTO_MODE="false"
DEPLOY_APP="true"

# Parse CLI arguments
for arg in "$@"; do
  case $arg in
    --auto)
      AUTO_MODE="true"
      shift
      ;;
    --hardware=*)
      HARDWARE_MODE="${arg#*=}"
      shift
      ;;
    --skip-app)
      DEPLOY_APP="false"
      shift
      ;;
    --help)
      echo "Usage: sudo ./bin/setup.sh [OPTIONS]"
      echo "Options:"
      echo "  --auto               Run in non-interactive fully automated mode"
      echo "  --hardware=TYPE      Specify hardware profile (auto, t2-mac, laptop, generic-pc)"
      echo "  --skip-app           Skip default app deployment (VN-MDM)"
      exit 0
      ;;
  esac
done

log "Starting Home Server Setup Pipeline..."
log "Mode: AUTO=$AUTO_MODE, HARDWARE=$HARDWARE_MODE, DEPLOY_APP=$DEPLOY_APP"

# Step 1: Hardware Detection & Driver Provisioning
SYSTEM_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
CHASSIS_TYPE=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")

log "Hardware specs: Vendor='$SYSTEM_VENDOR', Product='$PRODUCT_NAME', Chassis='$CHASSIS_TYPE'"

IS_T2_MAC="false"
if [[ "$SYSTEM_VENDOR" =~ "Apple" ]] || [[ "$PRODUCT_NAME" =~ "MacBookPro15" ]] || [[ "$PRODUCT_NAME" =~ "MacBook" ]]; then
  IS_T2_MAC="true"
fi

IS_LAPTOP="false"
# Chassis type 9 or 10 indicates laptop / notebook
if [[ "$CHASSIS_TYPE" == "9" ]] || [[ "$CHASSIS_TYPE" == "10" ]] || [[ "$PRODUCT_NAME" =~ "MacBook" ]]; then
  IS_LAPTOP="true"
fi

if [[ "$HARDWARE_MODE" == "t2-mac" ]] || { [[ "$HARDWARE_MODE" == "auto" ]] && [[ "$IS_T2_MAC" == "true" ]]; }; then
  log "Executing Apple T2 Mac driver setup..."
  bash "$SCRIPT_DIR/hardware/t2-mac/install_t2_drivers.sh"
elif [[ "$HARDWARE_MODE" == "generic-pc" ]]; then
  log "Using Generic PC hardware profile. Skipping custom driver kernel."
fi

if [[ "$IS_LAPTOP" == "true" ]]; then
  log "Laptop hardware detected. Applying lid-close sleep prevention..."
  bash "$SCRIPT_DIR/hardware/laptop-power/configure_power.sh"
fi

# Step 2: Core Infrastructure Modules
log "Phase 1/5: Core Base Utilities..."
bash "$SCRIPT_DIR/core/01_base_system.sh"

log "Phase 2/5: Core Database Services..."
bash "$SCRIPT_DIR/core/02_databases.sh"

log "Phase 3/5: Application Runtimes..."
bash "$SCRIPT_DIR/core/03_runtimes.sh"

log "Phase 4/5: Nginx Web Server & UFW Firewall..."
bash "$SCRIPT_DIR/core/04_nginx_webserver.sh"

log "Phase 5/5: Remote Access Tools..."
bash "$SCRIPT_DIR/core/05_remote_access.sh"

# Step 3: Application Deployment
if [[ "$DEPLOY_APP" == "true" ]]; then
  log "Deploying primary application (VN-MDM)..."
  bash "$SCRIPT_DIR/apps/vn-mdm/deploy_vnmdm.sh"
fi

log "=========================================================="
log " 🎉 SERVER SETUP COMPLETE!"
log "=========================================================="
log " Server IP:   $(hostname -I | awk '{print $1}')"
log " Local MDNS:  http://$(hostname).local"
log " Tailscale:   sudo tailscale up (run manually to link account)"
log " Services:    sudo systemctl status nginx vnmdm-backend vnmdm-frontend"
log "=========================================================="
