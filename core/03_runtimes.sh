#!/bin/bash
# Backward-compatibility forwarder
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/platforms/ubuntu/runtimes/install_runtimes.sh" "$@"
