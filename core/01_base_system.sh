#!/bin/bash
###############################################################################
# Core Module 01: Base System Utilities & Build Tooling
###############################################################################
set -e
export DEBIAN_FRONTEND=noninteractive

log() { echo -e "\n\033[1;32m[CORE-01]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

REAL_USER="${SUDO_USER:-qa}"

log "Updating APT packages..."
apt update && apt upgrade -y

log "Installing base compilation and system utilities..."
apt install -y \
  git curl wget build-essential autoconf bison rustc libssl-dev \
  libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
  libreadline-dev libncurses5-dev libncursesw5-dev \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common pkg-config \
  imagemagick libvips sqlite3 libsqlite3-dev \
  unzip xz-utils tk-dev htop ufw net-tools ca-certificates gpg

log "Installing Google Chrome (headless / browser automation support)..."
if ! command -v google-chrome &>/dev/null; then
  wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  apt install -y /tmp/google-chrome.deb
  rm -f /tmp/google-chrome.deb
fi

log "Installing full Vim package..."
apt install -y vim

log "Installing Zsh..."
if ! command -v zsh &>/dev/null; then
  apt install -y zsh
fi

if ! grep -q "zsh" /etc/passwd | grep -q "$REAL_USER"; then
  log "Setting Zsh as default shell for $REAL_USER..."
  chsh -s "$(which zsh)" "$REAL_USER" || true
fi

apt autoremove -y
log "Base system installation complete."
