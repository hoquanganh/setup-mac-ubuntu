#!/bin/bash
###############################################################################
# Core Module 02: Database Services (PostgreSQL, Redis, MySQL, MongoDB)
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[CORE-02]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Setting up PostgreSQL..."
if ! command -v psql &>/dev/null; then
  apt install -y postgresql postgresql-contrib libpq-dev
fi
systemctl enable postgresql
systemctl start postgresql

log "Setting up Redis..."
if ! command -v redis-server &>/dev/null; then
  apt install -y redis-server
fi
systemctl enable redis-server
systemctl start redis-server

log "Setting up MySQL..."
if ! command -v mysql &>/dev/null; then
  apt install -y mysql-server
fi
systemctl enable mysql
systemctl start mysql
mysql -e "CREATE USER IF NOT EXISTS 'rails'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

log "Setting up MongoDB 7.0..."
if ! command -v mongod &>/dev/null; then
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null || true
  echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
  apt update
  apt install -y mongodb-org || warn "MongoDB install failed — may require manual resolution."
  systemctl daemon-reload
  systemctl enable mongod || true
  systemctl start mongod || true
fi

log "Databases setup complete."
