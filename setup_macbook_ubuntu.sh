#!/bin/bash
###############################################################################
# MacBook Pro T2 Setup Wrapper
# Forwarding execution to the new modular bin/setup.sh script
###############################################################################
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/bin/setup.sh" ]; then
  echo "[WRAPPER] Forwarding to new modular setup engine (bin/setup.sh)..."
  exec bash "$SCRIPT_DIR/bin/setup.sh" --hardware=t2-mac "$@"
else
  echo "[ERROR] bin/setup.sh not found."
  exit 1
fi
