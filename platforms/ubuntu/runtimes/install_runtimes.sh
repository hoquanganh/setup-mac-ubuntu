#!/bin/bash
###############################################################################
# Core Module 03: Programming Runtimes (Node.js 22, Ruby 3.3.6, Docker)
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[CORE-03]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

REAL_USER="${SUDO_USER:-qa}"
REAL_HOME=$(eval echo "~$REAL_USER")

run_as_user() {
  sudo -u "$REAL_USER" bash -c "$1"
}

log "Installing Node.js 22 & npm..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
fi
log "Node version: $(node -v)"

log "Installing Docker Engine & Docker Compose..."
if ! command -v docker &>/dev/null; then
  apt install -y docker.io docker-compose-v2
  usermod -aG docker "$REAL_USER" || true
  systemctl enable docker
  systemctl start docker
fi

log "Setting up rbenv & Ruby 3.3.6 for $REAL_USER..."
if [ ! -d "$REAL_HOME/.rbenv" ]; then
  run_as_user "git clone https://github.com/rbenv/rbenv.git $REAL_HOME/.rbenv"
  run_as_user "git clone https://github.com/rbenv/ruby-build.git $REAL_HOME/.rbenv/plugins/ruby-build"
fi

if ! run_as_user "grep -q 'rbenv' $REAL_HOME/.zshrc 2>/dev/null"; then
  run_as_user "echo '' >> $REAL_HOME/.zshrc"
  run_as_user "echo '# rbenv' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'export RBENV_ROOT=\"\$HOME/.rbenv\"' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'export PATH=\"\$RBENV_ROOT/bin:\$PATH\"' >> $REAL_HOME/.zshrc"
  run_as_user "echo 'eval \"\$(rbenv init - zsh)\"' >> $REAL_HOME/.zshrc"
fi

if ! run_as_user "grep -q 'rbenv' $REAL_HOME/.bashrc 2>/dev/null"; then
  run_as_user "echo '' >> $REAL_HOME/.bashrc"
  run_as_user "echo 'export RBENV_ROOT=\"\$HOME/.rbenv\"' >> $REAL_HOME/.bashrc"
  run_as_user "echo 'export PATH=\"\$RBENV_ROOT/bin:\$PATH\"' >> $REAL_HOME/.bashrc"
  run_as_user "echo 'eval \"\$(rbenv init - bash)\"' >> $REAL_HOME/.bashrc"
fi

if ! run_as_user "$REAL_HOME/.rbenv/bin/rbenv versions 2>/dev/null" | grep -q "3.3.6"; then
  log "Compiling Ruby 3.3.6 (this takes a few minutes)..."
  run_as_user "RBENV_ROOT=$REAL_HOME/.rbenv PATH=$REAL_HOME/.rbenv/bin:$REAL_HOME/.rbenv/plugins/ruby-build/bin:\$PATH rbenv install 3.3.6"
  run_as_user "RBENV_ROOT=$REAL_HOME/.rbenv PATH=$REAL_HOME/.rbenv/bin:\$PATH $REAL_HOME/.rbenv/bin/rbenv global 3.3.6"
fi

log "Runtimes setup complete."
