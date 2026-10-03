#!/bin/bash
###############################################################################
# 1-Click Zero-Thought Restore Script for THIS Machine
# Target: Apple MacBook Pro 2019 (T2 Chip) running Ubuntu
# Result: Restores 100% of the current 24/7 server setup:
#   - T2 drivers & Apple Wi-Fi firmware
#   - Power management (lid-close sleep prevention)
#   - PostgreSQL, Redis, Node.js, Ruby (rbenv), Docker
#   - Avahi mDNS (qa-MacBookPro15-2.local), OpenSSH, Tailscale
#   - Nginx reverse proxy routing
#   - VN-MDM Native Systemd services (backend, worker, frontend, ngrok)
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo -e "\n\033[1;32m[RESTORE-THIS-MACHINE]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run with root privileges: sudo ./bin/restore_current_machine.sh"
  exit 1
fi

log "=========================================================="
log " Starting 1-Click Restoration for MacBook Pro 2019 (Ubuntu)"
log "=========================================================="

# 1. Hardware T2 Drivers & Firmware
log "Step 1/8: Configuring Apple T2 Kernel & Wi-Fi firmware..."
if [ -f "$SCRIPT_DIR/hardware/t2-mac/install_t2_drivers.sh" ]; then
  bash "$SCRIPT_DIR/hardware/t2-mac/install_t2_drivers.sh"
fi

# 2. Power Management (Lid-close sleep prevention)
log "Step 2/8: Configuring Power Management (24/7 Server without sleeping)..."
if [ -f "$SCRIPT_DIR/hardware/laptop-power/configure_power.sh" ]; then
  bash "$SCRIPT_DIR/hardware/laptop-power/configure_power.sh"
fi

# 3. Base Utilities
log "Step 3/8: Installing Base Utilities, Compilers, zsh, vim..."
bash "$SCRIPT_DIR/platforms/ubuntu/base/install_base.sh"

# 4. Database Daemons (PostgreSQL, Redis)
log "Step 4/8: Provisioning PostgreSQL and Redis daemons..."
bash "$SCRIPT_DIR/platforms/ubuntu/databases/install_databases.sh"

# 5. Programming Runtimes (Ruby, Node, Docker)
log "Step 5/8: Setting up Node.js 22, Ruby (rbenv), and Docker..."
bash "$SCRIPT_DIR/platforms/ubuntu/runtimes/install_runtimes.sh"

# 6. Web Server & Firewall (Nginx, UFW)
log "Step 6/8: Configuring Nginx and UFW firewall..."
bash "$SCRIPT_DIR/platforms/ubuntu/services/install_nginx.sh"

# 7. Remote Access (Avahi mDNS, SSH, Tailscale, ngrok)
log "Step 7/8: Setting up Avahi mDNS (.local), OpenSSH, and Tailscale..."
bash "$SCRIPT_DIR/platforms/ubuntu/services/install_remote_access.sh"

# 8. Deploy VN-MDM Native Systemd Services
log "Step 8/8: Deploying VN-MDM application services (backend, worker, frontend, ngrok)..."
bash "$SCRIPT_DIR/apps/vn-mdm/native/deploy_vnmdm.sh"

log "=========================================================="
log " 🎉 RESTORATION COMPLETED SUCCESSFULLY!"
log "=========================================================="
log " Server IP:   $(hostname -I 2>/dev/null | awk '{print $1}')"
log " Local mDNS:  http://$(hostname).local"
log " Services:"
log "   - sudo systemctl status nginx"
log "   - sudo systemctl status vnmdm-backend"
log "   - sudo systemctl status vnmdm-worker"
log "   - sudo systemctl status vnmdm-frontend"
log "   - sudo systemctl status ngrok-vnmdm"
log "=========================================================="
