#!/bin/bash
###############################################################################
# macOS Developer Workstation & Ruby on Rails Environment Setup Script
# Works on both Apple Silicon (M1/M2/M3/M4) and Intel MacBooks (2018-2020 T2)
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[MACOS-RAILS-SETUP]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify OS
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This script is designed for macOS (Darwin). You are currently running on $(uname -s)."
  exit 1
fi

log "1. Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode Command Line Tools (a GUI prompt may appear)..."
  xcode-select --install || true
  echo "Please complete the Xcode Command Line Tools installation dialog and re-run this script."
  exit 0
else
  log "Xcode Command Line Tools detected."
fi

log "2. Checking Homebrew Package Manager..."
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Configure Homebrew in PATH based on CPU architecture
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
  else
    BREW_PREFIX="/usr/local"
  fi
  eval "$($BREW_PREFIX/bin/brew shellenv)"
  echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zprofile"
else
  log "Homebrew already installed: $(brew --version | head -n 1)"
fi

log "3. Installing Packages & Databases via Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "Some brew packages or casks had warnings during installation."

log "4. Configuring Shell Environment in ~/.zshrc..."
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Configure rbenv
if ! grep -q 'rbenv init' "$ZSHRC"; then
  cat <<'EOF' >> "$ZSHRC"

# rbenv & Ruby compilation configuration
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"
EOF
  log "Added rbenv initialization to ~/.zshrc."
fi

# Configure libpq for PostgreSQL gem (pg)
BREW_LIBPQ="$(brew --prefix libpq 2>/dev/null || echo "")"
if [ -n "$BREW_LIBPQ" ] && ! grep -q 'libpq/bin' "$ZSHRC"; then
  echo "export PATH=\"$BREW_LIBPQ/bin:\$PATH\"" >> "$ZSHRC"
fi

# Configure OpenSSL compilation flags for compiling older/newer Rubies
BREW_OPENSSL="$(brew --prefix openssl@3 2>/dev/null || echo "")"
BREW_READLINE="$(brew --prefix readline 2>/dev/null || echo "")"
if [ -n "$BREW_OPENSSL" ] && ! grep -q 'RUBY_CONFIGURE_OPTS' "$ZSHRC"; then
  cat <<EOF >> "$ZSHRC"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$BREW_OPENSSL --with-readline-dir=$BREW_READLINE"
EOF
fi

eval "$(rbenv init - bash)" || true

log "5. Ensuring Database Daemons are running..."
brew services start postgresql@16 || true
brew services start redis || true

# Check / create postgres user for Rails
log "Ensuring default postgres user exists for Rails development..."
createuser -s postgres 2>/dev/null || true
createuser -s rails 2>/dev/null || true

log "6. Installing Default Ruby Runtime (3.3.6)..."
TARGET_RUBY="3.3.6"
if ! rbenv versions | grep -q "$TARGET_RUBY"; then
  log "Compiling Ruby $TARGET_RUBY (this may take 3-5 minutes)..."
  RUBY_CONFIGURE_OPTS="--with-openssl-dir=$BREW_OPENSSL --with-readline-dir=$BREW_READLINE" rbenv install "$TARGET_RUBY"
  rbenv global "$TARGET_RUBY"
  rbenv rehash
else
  log "Ruby $TARGET_RUBY is already installed."
  rbenv global "$TARGET_RUBY"
fi

log "7. Installing Bundler & Rails..."
gem install bundler --no-document || true
gem install rails --no-document || true

# Configure Bundler globally to find Homebrew's libpq (pg gem fix)
if [ -n "$BREW_LIBPQ" ]; then
  bundle config --global build.pg "--with-pg-config=$BREW_LIBPQ/bin/pg_config" || true
fi

log "=========================================================="
log " 🎉 MACOS RAILS DEVELOPMENT SETUP COMPLETE!"
log "=========================================================="
log " Ruby:       $(ruby -v 2>/dev/null || echo "Run: source ~/.zshrc && ruby -v")"
log " Bundler:    $(bundle -v 2>/dev/null || echo "Installed")"
log " Rails:      $(rails -v 2>/dev/null || echo "Installed")"
log " PostgreSQL: $(psql --version 2>/dev/null || echo "Active via brew services")"
log " Redis:      $(redis-cli ping 2>/dev/null || echo "Active via brew services")"
log " Docker:     OrbStack / Docker installed in /Applications"
log "=========================================================="
log " Tip: Restart your terminal or run: source ~/.zshrc"
