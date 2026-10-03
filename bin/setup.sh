#!/bin/bash
###############################################################################
# Master Universal Multi-Platform Setup & Provisioning Engine
# Platforms: Ubuntu Linux (22.04 / 24.04 / 26.04), macOS (Intel / Apple Silicon)
# Hardware: Apple T2 Mac, Lenovo Desktop, Generic PC / NUC / VPS, Laptops
# Profiles: 24/7 Home Server, Developer Workstation, Minimal
###############################################################################
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo -e "\n\033[1;32m[SETUP-MASTER]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

show_help() {
  cat <<EOF
Usage: sudo ./bin/setup.sh [OPTIONS]

Options:
  --platform=TYPE       Target OS platform: auto (default), ubuntu, macos
  --hardware=TYPE       Hardware profile: auto (default), t2-mac, desktop-lenovo, laptop, generic-pc
  --profile=TYPE        Setup profile: server-247 (default), dev-workstation, minimal
  --app=APP_NAME        Primary app to deploy: vn-mdm (default), none
  --app-mode=MODE       App deployment mode: native (default, systemd), docker
  --auto                Run in non-interactive unattended mode
  --help                Show this help message

Examples:
  # Restore this MacBook Pro 2019 Ubuntu 24/7 server:
  sudo ./bin/setup.sh --auto

  # Setup fresh Lenovo desktop Ubuntu 24.04 as Dev Workstation + VN-MDM via Docker:
  sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=docker

  # Setup macOS for Rails development:
  ./bin/setup.sh --platform=macos --profile=dev-workstation
EOF
  exit 0
}

# Defaults
PLATFORM="auto"
HARDWARE="auto"
PROFILE="server-247"
APP="vn-mdm"
APP_MODE="native"
AUTO_MODE="false"

# Parse arguments
for arg in "$@"; do
  case $arg in
    --platform=*)   PLATFORM="${arg#*=}" ;;
    --hardware=*)   HARDWARE="${arg#*=}" ;;
    --profile=*)    PROFILE="${arg#*=}" ;;
    --app=*)        APP="${arg#*=}" ;;
    --app-mode=*)   APP_MODE="${arg#*=}" ;;
    --auto)         AUTO_MODE="true" ;;
    --help)         show_help ;;
    *)
      warn "Unknown option: $arg"
      ;;
  esac
done

# Detect Platform
OS_NAME="$(uname -s)"
if [ "$PLATFORM" == "auto" ]; then
  if [ "$OS_NAME" == "Darwin" ]; then
    PLATFORM="macos"
  elif [ "$OS_NAME" == "Linux" ]; then
    PLATFORM="ubuntu"
  else
    err "Unsupported operating system: $OS_NAME"
    exit 1
  fi
fi

# Root check for Ubuntu
if [ "$PLATFORM" == "ubuntu" ] && [ "$EUID" -ne 0 ]; then
  err "On Ubuntu, this script must be run with root privileges (sudo ./bin/setup.sh)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

log "Universal Setup Engine Initialized."
log "Configuration: PLATFORM=$PLATFORM | HARDWARE=$HARDWARE | PROFILE=$PROFILE | APP=$APP ($APP_MODE) | AUTO=$AUTO_MODE"

###############################################################################
# Branch 1: macOS Setup Pipeline
###############################################################################
if [ "$PLATFORM" == "macos" ]; then
  log "Executing macOS setup pipeline..."
  bash "$SCRIPT_DIR/platforms/macos/setup_macos_rails.sh"
  log "macOS setup completed!"
  exit 0
fi

###############################################################################
# Branch 2: Ubuntu Linux Setup Pipeline
###############################################################################

# Auto-detect Hardware on Linux
if [ "$HARDWARE" == "auto" ]; then
  SYSTEM_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
  PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
  CHASSIS_TYPE=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")

  if [[ "$SYSTEM_VENDOR" =~ "Apple" ]] || [[ "$PRODUCT_NAME" =~ "MacBookPro15" ]] || [[ "$PRODUCT_NAME" =~ "MacBook" ]]; then
    HARDWARE="t2-mac"
  elif [[ "$SYSTEM_VENDOR" =~ "Lenovo" ]] && [[ "$CHASSIS_TYPE" != "9" ]] && [[ "$CHASSIS_TYPE" != "10" ]]; then
    HARDWARE="desktop-lenovo"
  elif [[ "$CHASSIS_TYPE" == "9" ]] || [[ "$CHASSIS_TYPE" == "10" ]]; then
    HARDWARE="laptop"
  else
    HARDWARE="generic-pc"
  fi
  log "Auto-detected hardware: $HARDWARE (Vendor='$SYSTEM_VENDOR', Product='$PRODUCT_NAME')"
fi

# 1. Apply Hardware Configuration
log "Applying hardware configurations for: $HARDWARE..."
case $HARDWARE in
  t2-mac)
    log "Configuring Apple T2 drivers..."
    bash "$SCRIPT_DIR/hardware/t2-mac/install_t2_drivers.sh"
    log "Configuring laptop power management..."
    bash "$SCRIPT_DIR/hardware/laptop-power/configure_power.sh"
    ;;
  laptop)
    log "Configuring laptop lid sleep prevention..."
    bash "$SCRIPT_DIR/hardware/laptop-power/configure_power.sh"
    ;;
  desktop-lenovo)
    log "Configuring Lenovo Desktop optimizations..."
    bash "$SCRIPT_DIR/hardware/desktop-lenovo/configure_desktop.sh"
    ;;
  generic-pc)
    log "Generic PC profile selected. Skipping specialized driver tweaks."
    ;;
esac

# 2. Execute Profile
if [ "$PROFILE" == "dev-workstation" ]; then
  log "Executing Developer Workstation Profile..."
  bash "$SCRIPT_DIR/platforms/ubuntu/setup_dev_machine.sh"
else
  # Server-247 or Minimal Profile
  log "Phase 1/5: Base Utilities & Tooling..."
  bash "$SCRIPT_DIR/platforms/ubuntu/base/install_base.sh"

  log "Phase 2/5: Database Services..."
  bash "$SCRIPT_DIR/platforms/ubuntu/databases/install_databases.sh"

  log "Phase 3/5: Application Runtimes..."
  bash "$SCRIPT_DIR/platforms/ubuntu/runtimes/install_runtimes.sh"

  log "Phase 4/5: Nginx Web Server & Firewall..."
  bash "$SCRIPT_DIR/platforms/ubuntu/services/install_nginx.sh"

  log "Phase 5/5: Remote Access Tools (Avahi, SSH, Tailscale)..."
  bash "$SCRIPT_DIR/platforms/ubuntu/services/install_remote_access.sh"
fi

# 3. Application Deployment
if [ "$APP" == "vn-mdm" ]; then
  if [ "$APP_MODE" == "docker" ]; then
    log "Deploying VN-MDM via Docker Compose..."
    if [ -f "$SCRIPT_DIR/apps/vn-mdm/docker/docker-compose.yml" ]; then
      cd "$SCRIPT_DIR/apps/vn-mdm/docker"
      if [ ! -f .env ]; then
        cp .env.example .env
      fi
      docker compose up -d || warn "Docker Compose failed to start containers."
    fi
  else
    log "Deploying VN-MDM via Native Systemd Services & Nginx..."
    bash "$SCRIPT_DIR/apps/vn-mdm/native/deploy_vnmdm.sh"
  fi
fi

log "=========================================================="
log " 🎉 SETUP PROCESS COMPLETED!"
log "=========================================================="
log " Platform: $PLATFORM | Hardware: $HARDWARE | Profile: $PROFILE"
log " Local IP: $(hostname -I 2>/dev/null | awk '{print $1}')"
log " mDNS:     http://$(hostname).local"
log "=========================================================="
