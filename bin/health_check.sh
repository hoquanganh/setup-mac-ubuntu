#!/bin/bash
###############################################################################
# System & Service Health Monitor for Lenovo ThinkCentre M910q
# Checks: Core services, HTTP endpoints, PostgreSQL, and Disk space.
# Sends email alerts via Gmail SMTP (send_alert_email.py) upon failure.
###############################################################################
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALERT_SCRIPT="$SCRIPT_DIR/send_alert_email.py"
STATE_FILE="/tmp/vnmdm_health_alert_state"

FAILED_SERVICES=()
FAILED_PORTS=()
WARNINGS=()

# 1. Check Systemd Services
CHECK_SERVICES=(
  "vnmdm-backend.service"
  "vnmdm-worker.service"
  "vnmdm-frontend.service"
  "vn-mdm-landing.service"
  "cloudflared.service"
  "cloudflared-landing.service"
  "nginx.service"
  "postgresql@16-main.service"
)

for svc in "${CHECK_SERVICES[@]}"; do
  if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
    FAILED_SERVICES+=("$svc")
  fi
done

# 2. Check Local Endpoints
check_port() {
  local port=$1
  local name=$2
  if ! nc -z -w 3 127.0.0.1 "$port" 2>/dev/null; then
    FAILED_PORTS+=("$name (Port $port)")
  fi
}

check_port 3000 "Rails Backend"
check_port 3001 "Next.js Frontend"
check_port 4321 "Landing Page"
check_port 80 "Nginx Reverse Proxy"
check_port 5432 "PostgreSQL"

# 3. Check Disk Space (> 90% is critical)
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt 90 ]; then
  WARNINGS+=("Disk space critically low: / is at ${DISK_USAGE}% usage!")
fi

# 4. Evaluate Health Status
if [ ${#FAILED_SERVICES[@]} -gt 0 ] || [ ${#FAILED_PORTS[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
  ALERT_BODY="⚠️ System Health Check detected issues on $(hostname):\n\n"

  if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    ALERT_BODY+="🔴 Inactive / Failed Services:\n"
    for s in "${FAILED_SERVICES[@]}"; do
      ALERT_BODY+="  - $s\n"
    done
    ALERT_BODY+="\n"
  fi

  if [ ${#FAILED_PORTS[@]} -gt 0 ]; then
    ALERT_BODY+="🔴 Unreachable Local Ports:\n"
    for p in "${FAILED_PORTS[@]}"; do
      ALERT_BODY+="  - $p\n"
    done
    ALERT_BODY+="\n"
  fi

  if [ ${#WARNINGS[@]} -gt 0 ]; then
    ALERT_BODY+="🟠 System Warnings:\n"
    for w in "${WARNINGS[@]}"; do
      ALERT_BODY+="  - $w\n"
    done
    ALERT_BODY+="\n"
  fi

  ALERT_BODY+="Quick Diagnostic Commands:\n"
  ALERT_BODY+="  sudo systemctl status vnmdm-backend\n"
  ALERT_BODY+="  sudo systemctl status cloudflared\n"
  ALERT_BODY+="  journalctl -xe -u vnmdm-backend\n"

  echo -e "$ALERT_BODY"

  # Throttle alerts: Only send once every 2 hours if state has not cleared
  SEND_ALERT=true
  if [ -f "$STATE_FILE" ]; then
    LAST_SENT=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST_SENT))
    if [ "$DIFF" -lt 7200 ]; then
      SEND_ALERT=false
    fi
  fi

  if [ "$SEND_ALERT" = true ] && [ -x "$ALERT_SCRIPT" ]; then
    "$ALERT_SCRIPT" --status ERROR --subject "System Health Alert: Service Down" --message "$ALERT_BODY" || true
    touch "$STATE_FILE"
  fi
  exit 1
else
  # If system is healthy and previously was failing, notify recovery
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    if [ -x "$ALERT_SCRIPT" ]; then
      "$ALERT_SCRIPT" --status SUCCESS --subject "System Health Recovered" --message "All services and ports on $(hostname) have returned to healthy active state." || true
    fi
  fi
  echo "[OK] All core services, endpoints, and disk space are healthy."
  exit 0
fi
