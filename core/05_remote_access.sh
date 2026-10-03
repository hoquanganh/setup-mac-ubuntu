#!/bin/bash
# Backward-compatibility forwarder
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/platforms/ubuntu/services/install_remote_access.sh" "$@"
