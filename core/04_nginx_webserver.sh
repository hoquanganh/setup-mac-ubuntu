#!/bin/bash
###############################################################################
# Core Module 04: Nginx Web Server & Firewall (UFW)
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[CORE-04]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Installing Nginx & Certbot..."
apt install -y nginx certbot python3-certbot-nginx

log "Configuring UFW Firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable || true

systemctl enable nginx
systemctl start nginx

log "Nginx webserver & UFW setup complete."
