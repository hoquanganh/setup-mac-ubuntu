#!/bin/bash
###############################################################################
# Hardware Module: Apple T2 MacBook Drivers (Wi-Fi, Touchpad, Audio, Keyboard)
# Supported: MacBook Pro 2018-2020 (T2 Chip) running Ubuntu 24.04/26.04
###############################################################################
set -e

log() { echo -e "\n\033[1;32m[HARDWARE: T2-MAC]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (or via sudo)."
  exit 1
fi

log "Checking if machine is Apple T2 Mac..."
SYSTEM_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")

log "Detected Hardware: Vendor='$SYSTEM_VENDOR', Model='$PRODUCT_NAME'"

if [ ! -f /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg ]; then
  log "Adding T2Linux common repository key..."
  apt update
  apt install -y curl gpg
  curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" \
    | gpg --dearmor | tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
  curl -s --compressed -o /etc/apt/sources.list.d/t2.list \
    "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
else
  log "T2Linux common repo key already configured."
fi

if [ ! -f /etc/apt/sources.list.d/t2-release.list ]; then
  log "Adding T2Linux release repository (resolute)..."
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/resolute ./" \
    | tee /etc/apt/sources.list.d/t2-release.list
else
  log "T2Linux release repo already configured."
fi

apt update

if ! dpkg -l linux-t2 2>/dev/null | grep -q '^ii'; then
  log "Installing linux-t2 kernel, audio config, and firmware script..."
  apt install -y linux-t2 apple-t2-audio-config apple-firmware-script
else
  log "linux-t2 kernel already installed."
fi

if [ ! -f /lib/firmware/brcm/brcmfmac4364b3-pcie.bin ] && \
   [ ! -f /lib/firmware/brcm/brcmfmac4364b2-pcie.bin ]; then
  log "Extracting Wi-Fi/Bluetooth firmware from Apple Recovery (requires internet)..."
  get-apple-firmware -i get_from_online || warn "Firmware extraction failed. Execute manually: sudo get-apple-firmware get_from_online"
else
  log "Wi-Fi firmware already present."
fi

log "T2 Mac hardware setup finished."
