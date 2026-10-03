#!/bin/bash
###############################################################################
# Desktop Development Applications Installer for Ubuntu
# Installs: Google Chrome, Cursor IDE, Warp Terminal, TablePlus, Vietnamese Input
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[UBUNTU-DESKTOP-APPS]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
INSTALL_DIR="$REAL_HOME/Documents/Systems/install-packs"

mkdir -p "$INSTALL_DIR"
chown -R "$REAL_USER":"$REAL_USER" "$INSTALL_DIR" 2>/dev/null || true

# 1. Google Chrome
log "1. Checking Google Chrome..."
if ! command -v google-chrome &>/dev/null; then
  log "Downloading and installing Google Chrome..."
  TEMP_DEB="/tmp/google-chrome-stable_current_amd64.deb"
  wget -q -O "$TEMP_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  apt install -y "$TEMP_DEB" || apt --fix-broken install -y
  rm -f "$TEMP_DEB"
else
  log "Google Chrome already installed."
fi

# 2. Cursor IDE
log "2. Checking Cursor IDE..."
if ! command -v cursor &>/dev/null && [ ! -f /usr/local/bin/cursor ]; then
  log "Downloading Cursor AppImage..."
  CURSOR_TARGET="/opt/cursor.appimage"
  curl -fsSL "https://downloader.cursor.sh/linux/appImage/x64" -o "$CURSOR_TARGET" || warn "Cursor direct download requires browser or token. Install manually from https://cursor.com"
  if [ -f "$CURSOR_TARGET" ]; then
    chmod +x "$CURSOR_TARGET"
    ln -sf "$CURSOR_TARGET" /usr/local/bin/cursor
  fi
fi

# 3. Warp Terminal
log "3. Checking Warp Terminal..."
if ! command -v warp-terminal &>/dev/null; then
  log "Installing Warp Terminal repository..."
  curl -fsSL https://releases.warp.dev/linux/keys/warp.asc | gpg --dearmor -o /etc/apt/keyrings/warpdotdev.gpg --yes 2>/dev/null || true
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" | tee /etc/apt/sources.list.d/warpdotdev.list >/dev/null
  apt update && apt install -y warp-terminal || warn "Warp repository could not be installed, please download deb from https://app.warp.dev"
fi

# 4. TablePlus (AppImage & Desktop launcher)
log "4. Checking TablePlus AppImage..."
TABLEPLUS_BIN="$INSTALL_DIR/TablePlus-x64.AppImage"
TABLEPLUS_ICON="$INSTALL_DIR/tableplus-icon.png"

if [ ! -f "$TABLEPLUS_BIN" ]; then
  log "Downloading TablePlus AppImage..."
  curl -fsSL "https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage" -o "$TABLEPLUS_BIN" || true
  chmod +x "$TABLEPLUS_BIN" || true
fi

if [ ! -f "$TABLEPLUS_ICON" ]; then
  curl -fsSL "https://tableplus.com/resources/favicons/apple-icon-60x60.png" -o "$TABLEPLUS_ICON" || true
fi

DESKTOP_ENTRY_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$DESKTOP_ENTRY_DIR"
cat <<EOF > "$DESKTOP_ENTRY_DIR/tableplus.desktop"
[Desktop Entry]
Name=TablePlus
Exec=$TABLEPLUS_BIN
Icon=$TABLEPLUS_ICON
Type=Application
Categories=Development;
Terminal=false
EOF
chown "$REAL_USER":"$REAL_USER" "$DESKTOP_ENTRY_DIR/tableplus.desktop" 2>/dev/null || true
chmod +x "$DESKTOP_ENTRY_DIR/tableplus.desktop" 2>/dev/null || true
update-desktop-database "$DESKTOP_ENTRY_DIR" 2>/dev/null || true

# 5. Vietnamese Keyboard Support (ibus-bamboo)
log "5. Setting up Vietnamese Input (ibus-bamboo)..."
if ! command -v ibus-bamboo &>/dev/null; then
  add-apt-repository -y ppa:bamboo-engine/ibus-bamboo || true
  apt update || true
  apt install -y ibus ibus-bamboo || true
  log "ibus-bamboo installed. Run 'ibus restart' or configure in GNOME Region & Language settings."
fi

log "Desktop applications setup completed!"
