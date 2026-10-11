#!/bin/bash
###############################################################################
# Automated System & Data Restoration for Lenovo ThinkCentre M910q (Ubuntu 24.04)
# Target: Restores PostgreSQL databases, VN-MDM secrets, landing leads,
#         systemd services, nginx configs, and user credentials from a backup.
###############################################################################
set -eo pipefail

log() { echo -e "\n\033[1;32m[RESTORE-M910Q]\033[0m $1"; }
info() { echo -e "  \033[1;34m[INFO]\033[0m $1"; }
ok() { echo -e "  \033[1;32m[OK]\033[0m $1"; }
warn() { echo -e "  \033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script requires root privileges to restore databases and system secrets."
  err "Please run with: sudo bash $0 [path_to_backup.tar.gz]"
  exit 1
fi

REAL_USER="${SUDO_USER:-quanganhho}"
REAL_HOME=$(eval echo "~$REAL_USER")
BACKUP_ARCHIVE="${1:-}"

# If no archive specified, pick the newest in ~/backups/
if [ -z "$BACKUP_ARCHIVE" ]; then
  BACKUP_ARCHIVE=$(ls -t "$REAL_HOME/backups"/backup_m910q_*.tar.gz 2>/dev/null | head -n 1 || true)
fi

if [ -z "$BACKUP_ARCHIVE" ] || [ ! -f "$BACKUP_ARCHIVE" ]; then
  err "Backup archive not found: '${BACKUP_ARCHIVE}'"
  echo "Usage: sudo bash $0 /path/to/backup_m910q_YYYYMMDD_HHMMSS.tar.gz"
  exit 1
fi

log "=========================================================="
log " Starting Restoration from Archive:"
log " File: $BACKUP_ARCHIVE"
log " Target User: $REAL_USER ($REAL_HOME)"
log " Time: $(date '+%Y-%m-%d %H:%M:%S')"
log "=========================================================="

# -----------------------------------------------------------------------------
# Verify Checksum
# -----------------------------------------------------------------------------
CHECKSUM_FILE="${BACKUP_ARCHIVE}.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
  info "Verifying SHA256 checksum..."
  cd "$(dirname "$BACKUP_ARCHIVE")"
  if sha256sum -c "$(basename "$CHECKSUM_FILE")" &>/dev/null; then
    ok "SHA256 checksum verified successfully."
  else
    err "Checksum mismatch! Archive may be corrupted."
    exit 1
  fi
  cd - >/dev/null
else
  warn "No checksum file found. Skipping checksum verification."
fi

# -----------------------------------------------------------------------------
# Extract to Staging
# -----------------------------------------------------------------------------
RESTORE_TEMP="/tmp/restore_m910q_$$"
mkdir -p "$RESTORE_TEMP"
trap 'rm -rf "$RESTORE_TEMP"' EXIT

info "Extracting archive to temporary workspace ($RESTORE_TEMP)..."
tar -xzf "$BACKUP_ARCHIVE" -C "$RESTORE_TEMP"
ok "Archive extracted successfully."

# -----------------------------------------------------------------------------
# 1. Restore PostgreSQL Databases
# -----------------------------------------------------------------------------
log "Step 1/6: Restoring PostgreSQL databases..."
DB_DIR="$RESTORE_TEMP/databases/postgres"

if [ -d "$DB_DIR" ] && command -v psql &>/dev/null; then
  # Ensure Postgres is running
  systemctl start postgresql || true

  # Restore global roles if present
  if [ -f "$DB_DIR/pg_globals.sql" ]; then
    info "Restoring PostgreSQL global roles..."
    sudo -u postgres psql -f "$DB_DIR/pg_globals.sql" 2>/dev/null || true
    ok "Restored roles."
  fi

  # Restore each vn_mdm_* database
  for dump_file in "$DB_DIR"/vn_mdm_*.dump; do
    if [ -f "$dump_file" ]; then
      db_name=$(basename "$dump_file" .dump)
      info "Restoring database '$db_name'..."

      # Create DB if it doesn't exist
      if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | tr -d ' ' | grep -qw "$db_name"; then
        sudo -u postgres createdb -O "${REAL_USER}" "$db_name" 2>/dev/null || sudo -u postgres createdb "$db_name"
      fi

      # Restore using pg_restore
      sudo -u postgres pg_restore --clean --if-exists -d "$db_name" "$dump_file" 2>/dev/null || true
      ok "Restored database '$db_name'."
    fi
  done
else
  warn "No database dumps found or PostgreSQL not installed. Skipping DB restore."
fi

# -----------------------------------------------------------------------------
# 2. Restore VN-MDM Secrets & Storage
# -----------------------------------------------------------------------------
log "Step 2/6: Restoring VN-MDM application secrets & storage..."
APP_RESTORE="$RESTORE_TEMP/app/vn-mdm"

if [ -d "$APP_RESTORE" ]; then
  VNMDM_TARGET="$REAL_HOME/vn-mdm"
  if [ -d "$VNMDM_TARGET" ]; then
    # Master key & credentials
    if [ -f "$APP_RESTORE/config/master.key" ]; then
      mkdir -p "$VNMDM_TARGET/api/config"
      cp "$APP_RESTORE/config/master.key" "$VNMDM_TARGET/api/config/"
      if [ -f "$APP_RESTORE/config/credentials.yml.enc" ]; then
        cp "$APP_RESTORE/config/credentials.yml.enc" "$VNMDM_TARGET/api/config/"
      fi
      chown -R "$REAL_USER":"$REAL_USER" "$VNMDM_TARGET/api/config"
      chmod 600 "$VNMDM_TARGET/api/config/master.key"
      ok "Restored Rails master.key and encrypted credentials."
    fi

    # ActiveStorage uploads
    if [ -d "$APP_RESTORE/storage" ]; then
      mkdir -p "$VNMDM_TARGET/api/storage"
      cp -r "$APP_RESTORE/storage/"* "$VNMDM_TARGET/api/storage/" 2>/dev/null || true
      chown -R "$REAL_USER":"$REAL_USER" "$VNMDM_TARGET/api/storage"
      ok "Restored ActiveStorage files."
    fi

    # Environment files
    if [ -f "$APP_RESTORE/api/.env" ]; then
      cp "$APP_RESTORE/api/.env" "$VNMDM_TARGET/api/.env"
      chown "$REAL_USER":"$REAL_USER" "$VNMDM_TARGET/api/.env"
      ok "Restored api/.env"
    fi
  else
    warn "VN-MDM directory ($VNMDM_TARGET) does not exist yet. Please clone the repository first."
  fi
fi

# -----------------------------------------------------------------------------
# 3. Restore Landing Page Data & Secrets
# -----------------------------------------------------------------------------
log "Step 3/6: Restoring VN-MDM Landing data & configs..."
LANDING_RESTORE="$RESTORE_TEMP/app/vn-mdm-landing"

if [ -d "$LANDING_RESTORE" ]; then
  # /etc/vn-mdm-landing
  if [ -d "$LANDING_RESTORE/etc_vn-mdm-landing" ]; then
    mkdir -p /etc/vn-mdm-landing
    cp -r "$LANDING_RESTORE/etc_vn-mdm-landing/"* /etc/vn-mdm-landing/ 2>/dev/null || true
    chmod 600 /etc/vn-mdm-landing/* 2>/dev/null || true
    ok "Restored /etc/vn-mdm-landing configuration and tunnel keys."
  fi

  # /var/lib/vn-mdm-landing/leads.jsonl
  if [ -f "$LANDING_RESTORE/var_lib_vn-mdm-landing/leads.jsonl" ]; then
    mkdir -p /var/lib/vn-mdm-landing
    cp "$LANDING_RESTORE/var_lib_vn-mdm-landing/leads.jsonl" /var/lib/vn-mdm-landing/
    chown -R "$REAL_USER":"$REAL_USER" /var/lib/vn-mdm-landing
    ok "Restored landing leads database."
  fi
fi

# -----------------------------------------------------------------------------
# 4. Restore Network, Tunnel & Tailscale State
# -----------------------------------------------------------------------------
log "Step 4/6: Restoring Network, Tunnel & Tailscale state..."
NET_RESTORE="$RESTORE_TEMP/network"

if [ -d "$NET_RESTORE" ]; then
  if [ -f "$NET_RESTORE/tailscale/tailscaled.state" ]; then
    mkdir -p /var/lib/tailscale
    cp "$NET_RESTORE/tailscale/tailscaled.state" /var/lib/tailscale/
    chmod 600 /var/lib/tailscale/tailscaled.state
    ok "Restored Tailscale node state."
  fi

  if [ -d "$NET_RESTORE/etc_cloudflared" ]; then
    mkdir -p /etc/cloudflared
    cp -r "$NET_RESTORE/etc_cloudflared/"* /etc/cloudflared/ 2>/dev/null || true
    ok "Restored /etc/cloudflared."
  fi

  if [ -d "$NET_RESTORE/home_cloudflared" ]; then
    mkdir -p "$REAL_HOME/.cloudflared"
    cp -r "$NET_RESTORE/home_cloudflared/"* "$REAL_HOME/.cloudflared/" 2>/dev/null || true
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.cloudflared"
    ok "Restored ~/.cloudflared."
  fi
fi

# -----------------------------------------------------------------------------
# 5. Restore Systemd Units & Nginx Configs
# -----------------------------------------------------------------------------
log "Step 5/6: Restoring System Services & Nginx..."
SYS_RESTORE="$RESTORE_TEMP/system"

if [ -d "$SYS_RESTORE" ]; then
  # Nginx
  if [ -d "$SYS_RESTORE/nginx/sites-available" ]; then
    mkdir -p /etc/nginx/sites-available /etc/nginx/conf.d
    cp -r "$SYS_RESTORE/nginx/sites-available/"* /etc/nginx/sites-available/ 2>/dev/null || true
    if [ -d "$SYS_RESTORE/nginx/conf.d" ]; then
      cp -r "$SYS_RESTORE/nginx/conf.d/"* /etc/nginx/conf.d/ 2>/dev/null || true
    fi
    ok "Restored Nginx configs."
  fi

  # Systemd units
  if [ -d "$SYS_RESTORE/systemd" ]; then
    cp -r "$SYS_RESTORE/systemd/"*.service /etc/systemd/system/ 2>/dev/null || true
    systemctl daemon-reload
    ok "Restored systemd units and reloaded daemon."
  fi
fi

# -----------------------------------------------------------------------------
# 6. Restore User Profile & Dev Configs
# -----------------------------------------------------------------------------
log "Step 6/6: Restoring User Profile (SSH, AWS, Azure, Kube, Shell)..."
USER_RESTORE="$RESTORE_TEMP/user/$REAL_USER"

if [ -d "$USER_RESTORE" ]; then
  # SSH
  if [ -d "$USER_RESTORE/.ssh" ]; then
    mkdir -p "$REAL_HOME/.ssh"
    cp -r "$USER_RESTORE/.ssh/"* "$REAL_HOME/.ssh/" 2>/dev/null || true
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.ssh"
    chmod 700 "$REAL_HOME/.ssh"
    chmod 600 "$REAL_HOME/.ssh/id_"* 2>/dev/null || true
    ok "Restored ~/.ssh with correct permissions (0600)."
  fi

  # AWS
  if [ -d "$USER_RESTORE/.aws" ]; then
    mkdir -p "$REAL_HOME/.aws"
    cp -r "$USER_RESTORE/.aws/"* "$REAL_HOME/.aws/" 2>/dev/null || true
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.aws"
    chmod 600 "$REAL_HOME/.aws/"* 2>/dev/null || true
    ok "Restored ~/.aws."
  fi

  # Azure
  if [ -d "$USER_RESTORE/.azure" ]; then
    mkdir -p "$REAL_HOME/.azure"
    cp -r "$USER_RESTORE/.azure/"* "$REAL_HOME/.azure/" 2>/dev/null || true
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.azure"
    ok "Restored ~/.azure."
  fi

  # Kube
  if [ -f "$USER_RESTORE/.kube/config" ]; then
    mkdir -p "$REAL_HOME/.kube"
    cp "$USER_RESTORE/.kube/config" "$REAL_HOME/.kube/config"
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.kube"
    chmod 600 "$REAL_HOME/.kube/config"
    ok "Restored ~/.kube/config."
  fi

  # Shell dotfiles
  for dotfile in .zshrc .p10k.zsh .zsh_history .bashrc .bash_history .gitconfig .viminfo .vimrc; do
    if [ -f "$USER_RESTORE/$dotfile" ]; then
      cp "$USER_RESTORE/$dotfile" "$REAL_HOME/$dotfile"
      chown "$REAL_USER":"$REAL_USER" "$REAL_HOME/$dotfile"
    fi
  done
  ok "Restored shell dotfiles and history."
fi

log "=========================================================="
log " 🎉 RESTORATION COMPLETED SUCCESSFULLY!"
log "=========================================================="
log " Services to restart if needed:"
log "   sudo systemctl restart nginx postgresql"
log "   sudo systemctl restart vnmdm-backend vnmdm-worker vnmdm-frontend"
log "   sudo systemctl restart vn-mdm-landing cloudflared-landing"
log "=========================================================="

exit 0
