#!/bin/bash
###############################################################################
# Fully Automated Setup Script for Ubuntu 26.04 on MacBook Pro 15,2 (T2 chip)
#
# This script is designed to be run by an AI agent or manually after a fresh
# Ubuntu 26.04 installation on a 2019 MacBook Pro with T2 chip.
#
# Prerequisites:
#   - A USB Wi-Fi dongle or USB Ethernet adapter for initial internet access.
#   - The user's password must be provided via SUDO_PASS environment variable
#     or the script must be run as root.
#
# Usage:
#   SUDO_PASS=123456 bash /home/qa/Downloads/setup_macbook_ubuntu.sh
#   OR
#   echo "123456" | sudo -S bash /home/qa/Downloads/setup_macbook_ubuntu.sh
#
# The script is idempotent — safe to re-run if interrupted.
###############################################################################
set -e

export DEBIAN_FRONTEND=noninteractive

# --- Helper Functions ---
log() { echo -e "\n\033[1;32m[SETUP]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

# Ensure we are root
if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root. Use: echo '123456' | sudo -S bash $0"
  exit 1
fi

REAL_USER="${SUDO_USER:-qa}"
REAL_HOME=$(eval echo "~$REAL_USER")

run_as_user() {
  sudo -u "$REAL_USER" bash -c "$1"
}

###############################################################################
# PHASE 1: T2 MacBook Hardware Drivers (Wi-Fi, Touchpad, Audio, Keyboard)
###############################################################################
log "=== PHASE 1: T2 MacBook Hardware Drivers ==="

# 1a. Add T2Linux APT repositories
if [ ! -f /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg ]; then
  log "Adding T2Linux common repository..."
  apt update
  apt install -y curl gpg
  curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" \
    | gpg --dearmor | tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
  curl -s --compressed -o /etc/apt/sources.list.d/t2.list \
    "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
else
  log "T2Linux common repo already configured. Skipping."
fi

if [ ! -f /etc/apt/sources.list.d/t2-release.list ]; then
  log "Adding T2Linux release-specific repository (resolute)..."
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/resolute ./" \
    | tee /etc/apt/sources.list.d/t2-release.list
else
  log "T2Linux release repo already configured. Skipping."
fi

apt update

# 1b. Install T2 kernel and audio config
if ! dpkg -l linux-t2 2>/dev/null | grep -q '^ii'; then
  log "Installing linux-t2 kernel, audio config, and firmware script..."
  apt install -y linux-t2 apple-t2-audio-config apple-firmware-script
else
  log "linux-t2 kernel already installed. Skipping."
fi

# 1c. Extract Wi-Fi/Bluetooth firmware from Apple servers
if [ ! -f /lib/firmware/brcm/brcmfmac4364b3-pcie.bin ] && \
   [ ! -f /lib/firmware/brcm/brcmfmac4364b2-pcie.bin ]; then
  log "Extracting Wi-Fi/Bluetooth firmware from Apple (this takes a few minutes)..."
  get-apple-firmware -i get_from_online || warn "Firmware extraction failed. Run manually: sudo get-apple-firmware get_from_online"
else
  log "Wi-Fi firmware already present. Skipping."
fi

log "Phase 1 complete. T2 drivers installed."

###############################################################################
# PHASE 2: System Utilities (Chrome, Vietnamese Input, Zsh, Vim)
###############################################################################
log "=== PHASE 2: System Utilities ==="

# 2a. Google Chrome
if ! command -v google-chrome &>/dev/null; then
  log "Installing Google Chrome..."
  wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  apt install -y /tmp/google-chrome.deb
  rm -f /tmp/google-chrome.deb
else
  log "Google Chrome already installed. Skipping."
fi

# 2b. Vietnamese Input (ibus-unikey)
if ! dpkg -l ibus-unikey 2>/dev/null | grep -q '^ii'; then
  log "Installing Vietnamese input method (ibus-unikey)..."
  apt install -y ibus-unikey language-pack-vi
  run_as_user "ibus restart" || true
else
  log "ibus-unikey already installed. Skipping."
fi

# 2c. Vim (full package; Ubuntu ships vim-tiny by default)
if ! dpkg -l vim 2>/dev/null | grep -q '^ii'; then
  log "Installing Vim (replacing vim-tiny)..."
else
  log "Vim already installed. Checking for updates..."
fi
apt install -y vim

# 2d. Zsh
if ! command -v zsh &>/dev/null; then
  log "Installing Zsh..."
  apt install -y zsh
fi
# Set Zsh as default shell for the real user
if ! grep -q "zsh" /etc/passwd | grep -q "$REAL_USER"; then
  log "Setting Zsh as default shell for $REAL_USER..."
  chsh -s "$(which zsh)" "$REAL_USER" || true
fi

# 2e. Cleanup
apt autoremove -y

log "Phase 2 complete. System utilities installed."

###############################################################################
# PHASE 3: Ruby on Rails Development Tools
###############################################################################
log "=== PHASE 3: Ruby on Rails Development Environment ==="

# 3a. Base build dependencies
log "Installing build dependencies..."
apt install -y \
  git curl wget build-essential autoconf bison rustc libssl-dev \
  libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
  libreadline-dev libncurses5-dev libncursesw5-dev \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common pkg-config \
  imagemagick libvips \
  sqlite3 libsqlite3-dev \
  unzip xz-utils tk-dev

# 3b. PostgreSQL
if ! command -v psql &>/dev/null; then
  log "Installing PostgreSQL..."
  apt install -y postgresql postgresql-contrib libpq-dev
fi
systemctl enable postgresql
systemctl start postgresql
log "PostgreSQL is running."

# 3c. MySQL
if ! command -v mysql &>/dev/null; then
  log "Installing MySQL..."
  apt install -y mysql-server
fi
systemctl enable mysql
systemctl start mysql
# Create rails user in MySQL
log "Configuring MySQL rails user..."
mysql -e "CREATE USER IF NOT EXISTS 'rails'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
log "MySQL configured (user: rails, password: password)."

# 3d. Redis
if ! command -v redis-server &>/dev/null; then
  log "Installing Redis..."
  apt install -y redis-server
fi
systemctl enable redis-server
systemctl start redis-server
log "Redis is running."

# 3e. MongoDB 7.0 (using jammy repo as workaround)
if ! command -v mongod &>/dev/null; then
  log "Installing MongoDB 7.0..."
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null || true
  echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
  apt update
  apt install -y mongodb-org || warn "MongoDB install failed — may need manual setup."
  systemctl daemon-reload
  systemctl enable mongod
  systemctl start mongod
else
  log "MongoDB already installed. Skipping."
fi

# 3f. rbenv + Ruby (run as real user, not root)
if [ ! -d "$REAL_HOME/.rbenv" ]; then
  log "Installing rbenv..."
  run_as_user "git clone https://github.com/rbenv/rbenv.git $REAL_HOME/.rbenv"
  run_as_user "git clone https://github.com/rbenv/ruby-build.git $REAL_HOME/.rbenv/plugins/ruby-build"
else
  log "rbenv already installed. Skipping."
fi

# Add rbenv to zshrc if not already there
if ! run_as_user "grep -q 'rbenv' $REAL_HOME/.zshrc 2>/dev/null"; then
  log "Adding rbenv to .zshrc..."
  run_as_user "echo '' >> $REAL_HOME/.zshrc"
  run_as_user "echo '# rbenv' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'export RBENV_ROOT=\"\$HOME/.rbenv\"' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'export PATH=\"\$RBENV_ROOT/bin:\$PATH\"' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'eval \"\$(rbenv init - zsh)\"' >> $REAL_HOME/.zshrc"
fi

# Install Ruby 3.3.6
if ! run_as_user "$REAL_HOME/.rbenv/bin/rbenv versions 2>/dev/null" | grep -q "3.3.6"; then
  log "Installing Ruby 3.3.6 (this takes several minutes)..."
  run_as_user "RBENV_ROOT=$REAL_HOME/.rbenv PATH=$REAL_HOME/.rbenv/bin:$REAL_HOME/.rbenv/plugins/ruby-build/bin:\$PATH rbenv install 3.3.6"
  run_as_user "RBENV_ROOT=$REAL_HOME/.rbenv PATH=$REAL_HOME/.rbenv/bin:\$PATH $REAL_HOME/.rbenv/bin/rbenv global 3.3.6"
else
  log "Ruby 3.3.6 already installed. Skipping."
fi

# 3g. Node.js 22
if ! command -v node &>/dev/null; then
  log "Installing Node.js 22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
else
  log "Node.js already installed ($(node -v)). Skipping."
fi

log "Phase 3 complete. Rails development environment installed."

###############################################################################
# PHASE 4: DevOps / Cloud Tools
###############################################################################
log "=== PHASE 4: DevOps & Cloud Tools ==="

# 4a. GitHub CLI
if ! command -v gh &>/dev/null; then
  log "Installing GitHub CLI..."
  apt install -y gh
else
  log "GitHub CLI already installed. Skipping."
fi

# 4b. Azure CLI
if ! command -v az &>/dev/null; then
  log "Installing Azure CLI..."
  apt install -y apt-transport-https ca-certificates gnupg lsb-release
  curl -sLS https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | tee /usr/share/keyrings/microsoft.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
    | tee /etc/apt/sources.list.d/azure-cli.list
  apt update
  apt install -y azure-cli
else
  log "Azure CLI already installed. Skipping."
fi

# 4c. kubectl
if ! command -v kubectl &>/dev/null; then
  log "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/kubectl
else
  log "kubectl already installed. Skipping."
fi

# 4d. kubelogin
if ! command -v kubelogin &>/dev/null; then
  log "Installing kubelogin..."
  wget -q -O /tmp/kubelogin.zip "https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip"
  unzip -o /tmp/kubelogin.zip -d /tmp/kubelogin
  mv /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/local/bin/
  chmod +x /usr/local/bin/kubelogin
  rm -rf /tmp/kubelogin /tmp/kubelogin.zip
else
  log "kubelogin already installed. Skipping."
fi

# 4e. Tailscale (private VPN for remote access)
if ! command -v tailscale &>/dev/null; then
  log "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  log "Tailscale already installed. Checking for updates..."
  apt install -y tailscale || true
fi

# 4f. ngrok (public tunnel for demo / sharing)
if ! command -v ngrok &>/dev/null; then
  log "Installing ngrok..."
  if [ ! -f /etc/apt/sources.list.d/ngrok.list ]; then
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | gpg --dearmor | tee /etc/apt/trusted.gpg.d/ngrok.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com bookworm main" \
      | tee /etc/apt/sources.list.d/ngrok.list
    apt update
  fi
  apt install -y ngrok
else
  log "ngrok already installed. Checking for updates..."
  apt install -y ngrok || true
fi

log "Phase 4 complete. DevOps & remote access tools installed."

###############################################################################
# PHASE 5: Verify Everything
###############################################################################
log "=== PHASE 5: Verification ==="
echo ""
echo "  Kernel:      $(uname -r)"
echo "  Chrome:      $(google-chrome --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Vim:         $(vim --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  Zsh:         $(zsh --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Node.js:     $(node -v 2>/dev/null || echo 'NOT FOUND')"
echo "  npm:         $(npm -v 2>/dev/null || echo 'NOT FOUND')"
echo "  Ruby:        $(run_as_user "RBENV_ROOT=$REAL_HOME/.rbenv PATH=$REAL_HOME/.rbenv/shims:$REAL_HOME/.rbenv/bin:\$PATH ruby -v" 2>/dev/null || echo 'NOT FOUND')"
echo "  PostgreSQL:  $(psql --version 2>/dev/null || echo 'NOT FOUND')"
echo "  MySQL:       $(mysql --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Redis:       $(redis-server --version 2>/dev/null || echo 'NOT FOUND')"
echo "  MongoDB:     $(mongod --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  Git:         $(git --version 2>/dev/null || echo 'NOT FOUND')"
echo "  gh:          $(gh --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  Azure CLI:   $(az --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  kubectl:     $(kubectl version --client --short 2>/dev/null || echo 'NOT FOUND')"
echo "  kubelogin:   $(kubelogin --version 2>/dev/null || echo 'NOT FOUND')"
echo "  Tailscale:   $(tailscale version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "  ngrok:       $(ngrok version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo ""

log "============================================="
log "  ALL DONE! Your MacBook Pro is fully set up."
log "============================================="
log ""
log "IMPORTANT: If this is a fresh install, you MUST REBOOT to activate the T2 kernel."
log "After reboot, the internal keyboard, trackpad, audio, and Wi-Fi will all work."
log ""
log "Manual steps still needed after script:"
log "  1. 'gh auth login'                  — Authenticate GitHub CLI"
log "  2. 'az login'                       — Authenticate Azure CLI"
log "  3. 'sudo tailscale up'              — Authenticate Tailscale VPN"
log "  4. 'ngrok config add-authtoken ...' — Authenticate ngrok (get token from dashboard)"
log "  5. Copy ~/.ssh keys                 — For git clone access"
log "  6. Copy ~/.azure & ~/.kube          — For Kubernetes access"
log ""
log "Remote access docs: server-setup/remote_access_tools.md"
log ""
