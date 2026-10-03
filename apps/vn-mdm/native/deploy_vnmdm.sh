#!/bin/bash
###############################################################################
# App Deployment Script: VN-MDM (Rails API + Worker + Next.js Web + ngrok)
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

log "Deploying Systemd Services (backend, worker, frontend)..."
NPM_BIN=$(sudo -u "$REAL_USER" which npm 2>/dev/null || echo "$REAL_HOME/.nodenv/shims/npm")
BUNDLE_BIN=$(sudo -u "$REAL_USER" which bundle 2>/dev/null || echo "$REAL_HOME/.rbenv/shims/bundle")
EXTRA_PATH="$REAL_HOME/.nodenv/shims:$REAL_HOME/.rbenv/shims:$REAL_HOME/.rbenv/bin"

sed -e "s|/home/qa|$REAL_HOME|g" \
    -e "s|User=qa|User=$REAL_USER|g" \
    -e "s|/home/qa/.rbenv/shims/bundle|$BUNDLE_BIN|g" \
    "$SCRIPT_DIR/vnmdm-backend.service" > /etc/systemd/system/vnmdm-backend.service

sed -e "s|/home/qa|$REAL_HOME|g" \
    -e "s|User=qa|User=$REAL_USER|g" \
    -e "s|/home/qa/.rbenv/shims/bundle|$BUNDLE_BIN|g" \
    "$SCRIPT_DIR/vnmdm-worker.service" > /etc/systemd/system/vnmdm-worker.service

sed -e "s|/home/qa|$REAL_HOME|g" \
    -e "s|User=qa|User=$REAL_USER|g" \
    -e "s|/usr/bin/npm|$NPM_BIN|g" \
    -e "s|PATH=|PATH=$EXTRA_PATH:|g" \
    "$SCRIPT_DIR/vnmdm-frontend.service" > /etc/systemd/system/vnmdm-frontend.service

log "Deploying ngrok auto-start service..."
# Uses --domain flag in ExecStart to keep URL fixed across restarts.
# To update the domain: edit ngrok-vnmdm.service ExecStart, then re-run this script.
cp "$SCRIPT_DIR/ngrok-vnmdm.service" /etc/systemd/system/

log "Installing ngrok URL sync helper script..."
# Manual one-shot script — run only when ngrok URL actually changes.
# Normal operation: URL is fixed via --domain, this script is never needed.
cp "$SCRIPT_DIR/ngrok-url-sync.sh" /usr/local/bin/ngrok-url-sync.sh
chmod +x /usr/local/bin/ngrok-url-sync.sh

systemctl daemon-reload

log "Enabling all services to auto-start on boot..."
systemctl enable nginx vnmdm-backend vnmdm-worker vnmdm-frontend ngrok-vnmdm.service

log "Restarting all services..."
systemctl restart nginx         || true
systemctl restart vnmdm-backend || true
systemctl restart vnmdm-worker  || true
systemctl restart vnmdm-frontend || true
systemctl restart ngrok-vnmdm   || true

log "VN-MDM deployed and running."
log "Status check:"
systemctl status vnmdm-backend  --no-pager | head -n 5
systemctl status vnmdm-worker   --no-pager | head -n 5
systemctl status vnmdm-frontend --no-pager | head -n 5
systemctl status nginx          --no-pager | head -n 5
systemctl status ngrok-vnmdm   --no-pager | head -n 5

echo ""
echo "======================================================================="
echo "  If ngrok URL ever changes, run:"
echo "    sudo bash /usr/local/bin/ngrok-url-sync.sh"
echo "  Or pass the new URL directly:"
echo "    sudo bash /usr/local/bin/ngrok-url-sync.sh https://new-url.ngrok-free.app"
echo "======================================================================="
