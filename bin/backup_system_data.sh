#!/bin/bash
###############################################################################
# Automated System & Data Backup for Lenovo ThinkCentre M910q (Ubuntu 24.04)
# Target: VN-MDM Platform + System Configuration + Dev Credentials
#
# What this backs up:
# 1. PostgreSQL: all vn_mdm_* databases + global users/roles
# 2. VN-MDM Secrets: Rails master.key, credentials.yml.enc, ActiveStorage uploads
# 3. Landing Page: /etc/vn-mdm-landing (env & tunnel) + /var/lib/vn-mdm-landing/leads.jsonl
# 4. Remote & Network: Tailscale state, Cloudflare tunnel configs & tokens
# 5. System Config: Nginx VirtualHosts, Systemd service unit files
# 6. User Profile: SSH keys, AWS, Azure, Kube, Shell configs (.zshrc, .p10k, history, etc.)
# 7. Google Drive: Automatic upload via rclone (if 'gdrive' remote is configured)
# 8. Alerting: Sends email via Gmail SMTP (send_alert_email.py) if any step fails
###############################################################################
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SCRIPT="$SCRIPT_DIR/send_alert_email.py"

log() { echo -e "\n\033[1;32m[BACKUP-M910Q]\033[0m $1"; }
info() { echo -e "  \033[1;34m[INFO]\033[0m $1"; }
ok() { echo -e "  \033[1;32m[OK]\033[0m $1"; }
warn() { echo -e "  \033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

# -----------------------------------------------------------------------------
# Error Trap & Email Alert
# -----------------------------------------------------------------------------
on_error() {
  local exit_code=$?
  local line_no=$1
  local cmd="$2"
  err "Backup failed at line $line_no (Command: '$cmd', Exit code: $exit_code)"

  if [ -x "$ALERT_SCRIPT" ]; then
    local err_msg="Backup execution FAILED on $(hostname).\nFailed Line: $line_no\nCommand: $cmd\nExit Code: $exit_code\nTimestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    "$ALERT_SCRIPT" --status ERROR --subject "Weekly Backup FAILED" --message "$err_msg" || true
  fi

  # Clean up staging if exists
  if [ -n "${STAGING_DIR:-}" ] && [ -d "$STAGING_DIR" ]; then
    rm -rf "$STAGING_DIR"
  fi
  exit "$exit_code"
}
trap 'on_error $LINENO "$BASH_COMMAND"' ERR

# -----------------------------------------------------------------------------
# Privileges & Paths
# -----------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  err "This script requires root privileges to dump databases and read protected system secrets."
  err "Please run with: sudo bash $0"
  exit 1
fi

REAL_USER="${SUDO_USER:-quanganhho}"
REAL_HOME=$(eval echo "~$REAL_USER")
BACKUP_DIR="${BACKUP_DEST:-$REAL_HOME/backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="backup_m910q_${TIMESTAMP}"
STAGING_DIR="$BACKUP_DIR/.staging_${TIMESTAMP}"
ARCHIVE_FILE="$BACKUP_DIR/${ARCHIVE_NAME}.tar.gz"

NOTIFY_ON_SUCCESS=false
UPLOAD_GDRIVE=true

for arg in "$@"; do
  case "$arg" in
    --notify-email)
      NOTIFY_ON_SUCCESS=true
      ;;
    --no-gdrive)
      UPLOAD_GDRIVE=false
      ;;
    --dest=*)
      BACKUP_DIR="${arg#*=}"
      ARCHIVE_FILE="$BACKUP_DIR/${ARCHIVE_NAME}.tar.gz"
      STAGING_DIR="$BACKUP_DIR/.staging_${TIMESTAMP}"
      ;;
  esac
done

mkdir -p "$BACKUP_DIR"
mkdir -p "$STAGING_DIR"

log "=========================================================="
log " Starting System & Data Backup for $(hostname)"
log " User: $REAL_USER | Time: $(date '+%Y-%m-%d %H:%M:%S')"
log " Destination: $ARCHIVE_FILE"
log "=========================================================="

# -----------------------------------------------------------------------------
# 1. PostgreSQL (vn_mdm_* databases only)
# -----------------------------------------------------------------------------
log "Step 1/7: Dumping PostgreSQL databases (vn_mdm_* only)..."
DB_DIR="$STAGING_DIR/databases/postgres"
mkdir -p "$DB_DIR"

if command -v pg_dumpall &>/dev/null && systemctl is-active --quiet postgresql; then
  # Global roles & permissions
  info "Dumping PostgreSQL global roles & users..."
  sudo -u postgres pg_dumpall --globals-only > "$DB_DIR/pg_globals.sql"
  ok "Saved global roles to pg_globals.sql"

  # Find all vn_mdm_* databases
  VNMDM_DBS=$(sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | tr -d ' ' | grep -E '^vn_mdm' || true)

  if [ -n "$VNMDM_DBS" ]; then
    for db in $VNMDM_DBS; do
      info "Dumping PostgreSQL database: $db..."
      # Custom format (-Fc) is compressed, flexible, and allows selective restore
      sudo -u postgres pg_dump -Fc "$db" > "$DB_DIR/${db}.dump"
      # Also keep a plain compressed SQL file for easy reading
      sudo -u postgres pg_dump "$db" | gzip -9 > "$DB_DIR/${db}.sql.gz"
      ok "Successfully dumped $db ($(du -h "$DB_DIR/${db}.dump" | cut -f1))"
    done
  else
    warn "No databases matching 'vn_mdm_*' were found in PostgreSQL."
  fi
else
  warn "PostgreSQL service is not running or tools are missing. Skipping DB dump."
fi

# -----------------------------------------------------------------------------
# 2. VN-MDM Secrets & Storage
# -----------------------------------------------------------------------------
log "Step 2/7: Backing up VN-MDM application secrets & storage..."
APP_DIR="$STAGING_DIR/app/vn-mdm"
mkdir -p "$APP_DIR"

# Master key & credentials
if [ -f "$REAL_HOME/vn-mdm/api/config/master.key" ]; then
  info "Backing up Rails master.key & credentials.yml.enc..."
  mkdir -p "$APP_DIR/config"
  cp "$REAL_HOME/vn-mdm/api/config/master.key" "$APP_DIR/config/"
  if [ -f "$REAL_HOME/vn-mdm/api/config/credentials.yml.enc" ]; then
    cp "$REAL_HOME/vn-mdm/api/config/credentials.yml.enc" "$APP_DIR/config/"
  fi
  ok "Saved master.key and encrypted credentials."
else
  warn "Rails master.key not found at $REAL_HOME/vn-mdm/api/config/master.key"
fi

# ActiveStorage uploads (brand logos, enrollment payloads, files)
if [ -d "$REAL_HOME/vn-mdm/api/storage" ]; then
  info "Backing up VN-MDM ActiveStorage files..."
  cp -r "$REAL_HOME/vn-mdm/api/storage" "$APP_DIR/"
  ok "Saved storage directory ($(du -sh "$REAL_HOME/vn-mdm/api/storage" 2>/dev/null | cut -f1))"
fi

# Any local env overrides in api or web
for env_file in "$REAL_HOME/vn-mdm/api/.env" "$REAL_HOME/vn-mdm/api/.env.local" "$REAL_HOME/vn-mdm/web/.env.local"; do
  if [ -f "$env_file" ]; then
    rel_path="${env_file#$REAL_HOME/vn-mdm/}"
    mkdir -p "$APP_DIR/$(dirname "$rel_path")"
    cp "$env_file" "$APP_DIR/$rel_path"
    ok "Saved $rel_path"
  fi
done

# -----------------------------------------------------------------------------
# 3. VN-MDM Landing Page Data & Secrets
# -----------------------------------------------------------------------------
log "Step 3/7: Backing up VN-MDM Landing data & tunnels..."
LANDING_DIR="$STAGING_DIR/app/vn-mdm-landing"
mkdir -p "$LANDING_DIR"

# Landing env & tunnel credentials
if [ -d "/etc/vn-mdm-landing" ]; then
  info "Backing up /etc/vn-mdm-landing (app.env, tunnel.env)..."
  cp -r "/etc/vn-mdm-landing" "$LANDING_DIR/etc_vn-mdm-landing"
  ok "Saved /etc/vn-mdm-landing"
fi

# Landing leads database
if [ -f "/var/lib/vn-mdm-landing/leads.jsonl" ]; then
  info "Backing up landing leads database (/var/lib/vn-mdm-landing/leads.jsonl)..."
  mkdir -p "$LANDING_DIR/var_lib_vn-mdm-landing"
  cp "/var/lib/vn-mdm-landing/leads.jsonl" "$LANDING_DIR/var_lib_vn-mdm-landing/"
  ok "Saved leads.jsonl ($(wc -l < "/var/lib/vn-mdm-landing/leads.jsonl") records)"
fi

# -----------------------------------------------------------------------------
# 4. Network, Tunnels & Tailscale
# -----------------------------------------------------------------------------
log "Step 4/7: Backing up Network, Tunnel tokens & Tailscale state..."
NET_DIR="$STAGING_DIR/network"
mkdir -p "$NET_DIR"

# Tailscale node state
if [ -f "/var/lib/tailscale/tailscaled.state" ]; then
  info "Backing up Tailscale node state..."
  mkdir -p "$NET_DIR/tailscale"
  cp "/var/lib/tailscale/tailscaled.state" "$NET_DIR/tailscale/"
  ok "Saved Tailscale state"
fi

# Cloudflare Tunnel configs
if [ -d "/etc/cloudflared" ]; then
  info "Backing up /etc/cloudflared..."
  cp -r "/etc/cloudflared" "$NET_DIR/etc_cloudflared"
  ok "Saved /etc/cloudflared"
fi

if [ -d "$REAL_HOME/.cloudflared" ]; then
  info "Backing up $REAL_HOME/.cloudflared..."
  cp -r "$REAL_HOME/.cloudflared" "$NET_DIR/home_cloudflared"
  ok "Saved ~/.cloudflared"
fi

# -----------------------------------------------------------------------------
# 5. System Services & Nginx
# -----------------------------------------------------------------------------
log "Step 5/7: Backing up Nginx configs & Systemd services..."
SYS_DIR="$STAGING_DIR/system"
mkdir -p "$SYS_DIR/nginx" "$SYS_DIR/systemd"

# Nginx
if [ -d "/etc/nginx/sites-available" ]; then
  cp -r /etc/nginx/sites-available "$SYS_DIR/nginx/"
fi
if [ -d "/etc/nginx/conf.d" ]; then
  cp -r /etc/nginx/conf.d "$SYS_DIR/nginx/"
fi
ok "Saved Nginx configuration"

# Systemd Units
for unit in vnmdm-backend.service vnmdm-worker.service vnmdm-frontend.service \
            vn-mdm-landing.service cloudflared.service cloudflared-landing.service \
            vnmdm-backup.service vnmdm-backup.timer; do
  if [ -f "/etc/systemd/system/$unit" ]; then
    cp "/etc/systemd/system/$unit" "$SYS_DIR/systemd/"
    info "Saved systemd unit: $unit"
  fi
done
ok "Saved Systemd unit files"

# -----------------------------------------------------------------------------
# 6. User Profile, SSH, Cloud CLI & Shell Configs
# -----------------------------------------------------------------------------
log "Step 6/7: Backing up User Profile, SSH, AWS, Azure, Kube & Shell configs..."
USER_DIR="$STAGING_DIR/user/$REAL_USER"
mkdir -p "$USER_DIR"

# SSH keys & configs
if [ -d "$REAL_HOME/.ssh" ]; then
  info "Backing up ~/.ssh keys & configs..."
  cp -r "$REAL_HOME/.ssh" "$USER_DIR/"
  ok "Saved ~/.ssh"
fi

# AWS CLI
if [ -d "$REAL_HOME/.aws" ]; then
  info "Backing up ~/.aws configs..."
  cp -r "$REAL_HOME/.aws" "$USER_DIR/"
  ok "Saved ~/.aws"
fi

# Azure CLI
if [ -d "$REAL_HOME/.azure" ]; then
  info "Backing up ~/.azure session & configs..."
  mkdir -p "$USER_DIR/.azure"
  for f in config az.json az.sess azureProfile.json clouds.config msal_token_cache.json; do
    if [ -f "$REAL_HOME/.azure/$f" ]; then
      cp "$REAL_HOME/.azure/$f" "$USER_DIR/.azure/"
    fi
  done
  ok "Saved ~/.azure"
fi

# Kubernetes config
if [ -f "$REAL_HOME/.kube/config" ]; then
  info "Backing up ~/.kube/config..."
  mkdir -p "$USER_DIR/.kube"
  cp "$REAL_HOME/.kube/config" "$USER_DIR/.kube/"
  ok "Saved ~/.kube/config"
fi

# Shell configs & histories
for dotfile in .zshrc .p10k.zsh .zsh_history .bashrc .bash_history .gitconfig .viminfo .vimrc; do
  if [ -f "$REAL_HOME/$dotfile" ]; then
    cp "$REAL_HOME/$dotfile" "$USER_DIR/"
  fi
done
ok "Saved Shell configs (.zshrc, .p10k, history, .gitconfig)"

# -----------------------------------------------------------------------------
# 7. Package, Checksum & Compress
# -----------------------------------------------------------------------------
log "Step 7/7: Creating compressed backup tarball & checksum..."

# Generate Manifest
MANIFEST_FILE="$STAGING_DIR/manifest.txt"
cat <<EOF > "$MANIFEST_FILE"
================================================================================
                    VN-MDM & M910Q SYSTEM BACKUP MANIFEST
================================================================================
Timestamp:       $(date -u +"%Y-%m-%d %H:%M:%S UTC") ($(date +"%Y-%m-%d %H:%M:%S %Z"))
Host:            $(hostname)
OS Kernel:       $(uname -srm)
Distribution:    $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
User:            $REAL_USER (UID: $(id -u "$REAL_USER"))
Archive:         $ARCHIVE_NAME.tar.gz

--- Repositories Git Commit State ---
EOF

for repo_path in "$REAL_HOME/vn-mdm" "$REAL_HOME/vn-mdm-landing" "$SCRIPT_DIR/.."; do
  if [ -d "$repo_path/.git" ]; then
    echo "Repo: $(basename "$repo_path")" >> "$MANIFEST_FILE"
    echo "  Commit: $(git -C "$repo_path" rev-parse HEAD 2>/dev/null || echo 'N/A')" >> "$MANIFEST_FILE"
    echo "  Branch: $(git -C "$repo_path" branch --show-current 2>/dev/null || echo 'N/A')" >> "$MANIFEST_FILE"
  fi
done

echo "" >> "$MANIFEST_FILE"
echo "--- Backed Up File Inventory ---" >> "$MANIFEST_FILE"
find "$STAGING_DIR" -type f | sed "s|$STAGING_DIR/||g" | sort >> "$MANIFEST_FILE"

# Compress staging directory
tar -czf "$ARCHIVE_FILE" -C "$STAGING_DIR" .
rm -rf "$STAGING_DIR"

# Checksum
sha256sum "$ARCHIVE_FILE" > "${ARCHIVE_FILE}.sha256"

# Ensure proper user ownership of the backup files
chown -R "$REAL_USER":"$REAL_USER" "$BACKUP_DIR"

ARCHIVE_SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
ok "Archive created: $ARCHIVE_FILE ($ARCHIVE_SIZE)"
ok "Checksum saved:   ${ARCHIVE_FILE}.sha256"

# -----------------------------------------------------------------------------
# Local Retention Policy: Keep last 4 backups
# -----------------------------------------------------------------------------
info "Checking local backup retention (keeping 4 most recent archives)..."
OLD_BACKUPS=$(ls -t "$BACKUP_DIR"/backup_m910q_*.tar.gz 2>/dev/null | tail -n +5 || true)
if [ -n "$OLD_BACKUPS" ]; then
  for old_f in $OLD_BACKUPS; do
    info "Pruning old archive: $old_f"
    rm -f "$old_f" "${old_f}.sha256"
  done
  ok "Old local backups pruned."
fi

# -----------------------------------------------------------------------------
# Google Drive Upload via rclone
# -----------------------------------------------------------------------------
GDRIVE_STATUS="Not uploaded"
if [ "$UPLOAD_GDRIVE" = true ]; then
  if command -v rclone &>/dev/null; then
    # Check if a remote named 'gdrive' exists in rclone config (for real user or root)
    if sudo -u "$REAL_USER" rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
      log "Uploading backup archive to Google Drive (gdrive:Backups/$(hostname)/)..."
      if sudo -u "$REAL_USER" rclone copy "$ARCHIVE_FILE" "gdrive:Backups/$(hostname)/" \
         && sudo -u "$REAL_USER" rclone copy "${ARCHIVE_FILE}.sha256" "gdrive:Backups/$(hostname)/"; then
        ok "Successfully uploaded to Google Drive: gdrive:Backups/$(hostname)/$(basename "$ARCHIVE_FILE")"
        GDRIVE_STATUS="Uploaded to Google Drive (gdrive:Backups/$(hostname)/)"
      else
        warn "Failed to upload to Google Drive. Backup is safely kept locally."
        GDRIVE_STATUS="Failed to upload (Local copy intact)"
      fi
    else
      info "Google Drive remote ('gdrive:') not configured in rclone yet."
      info "To link Google Drive, run as user $REAL_USER: rclone config"
      GDRIVE_STATUS="Pending rclone configuration (Local copy intact)"
    fi
  else
    info "rclone is not installed. Skipping Google Drive upload."
  fi
fi

# -----------------------------------------------------------------------------
# Success Notification
# -----------------------------------------------------------------------------
log "=========================================================="
log " 🎉 BACKUP COMPLETED SUCCESSFULLY!"
log " Archive: $ARCHIVE_FILE ($ARCHIVE_SIZE)"
log " Google Drive: $GDRIVE_STATUS"
log "=========================================================="

if [ "$NOTIFY_ON_SUCCESS" = true ] && [ -x "$ALERT_SCRIPT" ]; then
  SUCCESS_MSG="Weekly backup for $(hostname) completed successfully.\n\nArchive: $(basename "$ARCHIVE_FILE")\nSize: $ARCHIVE_SIZE\nPath: $ARCHIVE_FILE\nGoogle Drive Status: $GDRIVE_STATUS\nTimestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  "$ALERT_SCRIPT" --status SUCCESS --subject "Weekly Backup Completed" --message "$SUCCESS_MSG" || true
fi

exit 0
