#!/bin/bash
###############################################################################
# App Deployment Script: VN-MDM (Rails API + Next.js Web)
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[APP: VN-MDM]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

REAL_USER="${SUDO_USER:-qa}"
REAL_HOME=$(eval echo "~$REAL_USER")
APP_DIR="$REAL_HOME/vn-mdm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Checking VN-MDM codebase directory: $APP_DIR..."

if [ ! -d "$APP_DIR" ]; then
  log "Cloning VN-MDM repository..."
  sudo -u "$REAL_USER" git clone https://github.com/quanganh/vn-mdm.git "$APP_DIR" || true
fi

log "Deploying Nginx VirtualHost configuration..."
cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/vnmdm
ln -sf /etc/nginx/sites-available/vnmdm /etc/nginx/sites-enabled/vnmdm
rm -f /etc/nginx/sites-enabled/default || true

log "Testing Nginx configuration..."
nginx -t

log "Deploying Systemd Services..."
cp "$SCRIPT_DIR/vnmdm-backend.service" /etc/systemd/system/
cp "$SCRIPT_DIR/vnmdm-frontend.service" /etc/systemd/system/

systemctl daemon-reload
systemctl enable vnmdm-backend vnmdm-frontend nginx
systemctl restart nginx || true
systemctl restart vnmdm-backend || true
systemctl restart vnmdm-frontend || true

log "VN-MDM deployed and running."
log "Status check:"
systemctl status vnmdm-backend --no-pager | head -n 5
systemctl status vnmdm-frontend --no-pager | head -n 5
systemctl status nginx --no-pager | head -n 5
