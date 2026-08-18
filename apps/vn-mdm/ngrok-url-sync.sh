#!/bin/bash
# ngrok-url-sync.sh — Cập nhật Rails DB khi ngrok URL thay đổi
#
# Chạy thủ công 1 lần khi nào URL ngrok thay đổi (restart server / xóa DB)
# Không cần chạy liên tục — ngrok dùng static domain nên URL cố định.
#
# Usage:
#   sudo bash /usr/local/bin/ngrok-url-sync.sh
#   sudo bash /usr/local/bin/ngrok-url-sync.sh https://your-new-url.ngrok-free.app
#
# What it does:
#   1. Lấy URL hiện tại từ ngrok local API (hoặc từ argument nếu truyền vào)
#   2. Ghi vào api/tmp/.ngrok_url (Rails đọc file này tự động)
#   3. Chạy refresh_ade_config.rb để update DB + ADE enrollment profile URLs

set -euo pipefail

REAL_USER="qa"
APP_DIR="/home/qa/vn-mdm/api"
URL_CACHE="$APP_DIR/tmp/.ngrok_url"
NGROK_API="http://127.0.0.1:4040/api/tunnels"
RBENV_PATH="/home/$REAL_USER/.rbenv/shims:/home/$REAL_USER/.rbenv/bin"

log()  { echo -e "\033[1;32m[ngrok-sync]\033[0m $1"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; exit 1; }

# --- 1. Xác định URL mới ---
if [ -n "${1:-}" ]; then
  # URL truyền vào thủ công
  NEW_URL="${1%/}"  # bỏ trailing slash
  log "Using provided URL: $NEW_URL"
else
  # Lấy từ ngrok API
  if ! curl -sf "$NGROK_API" > /dev/null 2>&1; then
    err "ngrok không chạy (cổng 4040 không phản hồi). Khởi động ngrok trước:\n  sudo systemctl start ngrok-vnmdm"
  fi
  NEW_URL=$(
    curl -sf "$NGROK_API" | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
urls = [t['public_url'] for t in data.get('tunnels', []) if t.get('proto') == 'https']
print(urls[0].rstrip('/') if urls else '')
" 2>/dev/null || true
  )
  [ -z "$NEW_URL" ] && err "Không tìm thấy HTTPS tunnel trong ngrok API."
  log "Detected URL from ngrok: $NEW_URL"
fi

# --- 2. So sánh với URL hiện tại ---
OLD_URL=""
[ -f "$URL_CACHE" ] && OLD_URL=$(cat "$URL_CACHE")

if [ "$NEW_URL" = "$OLD_URL" ]; then
  log "URL không thay đổi ($NEW_URL) — không cần cập nhật."
  exit 0
fi

# --- 3. Ghi vào cache file (Rails đọc file này) ---
mkdir -p "$(dirname "$URL_CACHE")"
echo -n "$NEW_URL" > "$URL_CACHE"
chown "$REAL_USER":"$REAL_USER" "$URL_CACHE" 2>/dev/null || true
log "Saved to $URL_CACHE: $NEW_URL"

# --- 4. Update Rails DB + ADE enrollment profile URLs ---
log "Running refresh_ade_config.rb ..."
cd "$APP_DIR"

OUTPUT=$(
  sudo -u "$REAL_USER" env \
    PATH="$RBENV_PATH:/usr/local/bin:/usr/bin:/bin" \
    MDM_SERVER_URL="$NEW_URL" \
    RAILS_ENV=development \
    SKIP_SYNC=1 \
  /home/"$REAL_USER"/.rbenv/shims/bundle exec rails runner script/refresh_ade_config.rb 2>&1
) && STATUS="OK" || STATUS="FAILED"

echo "$OUTPUT"

if [ "$STATUS" = "FAILED" ]; then
  err "refresh_ade_config.rb thất bại — URL đã được lưu vào $URL_CACHE nhưng DB chưa cập nhật."
fi

log "Done — ngrok URL synced: $NEW_URL"
echo ""
echo "  Truy cập server: $NEW_URL"
echo "  Admin UI:        $NEW_URL/platform/login"
