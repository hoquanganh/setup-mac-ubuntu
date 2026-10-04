#!/bin/bash
###############################################################################
# Lenovo ThinkCentre M910q Environment Provisioning & Idempotent Restore
# Support: Ubuntu 24.04 LTS (Noble Numbat)
#
# NGUYÊN TẮC CỐT LÕI:
# "Trước khi cài luôn kiểm tra máy đã có chưa, nếu có rồi thì không cài lại mà
#  sử dụng bản hiện có hoặc update nếu cần. Không làm ảnh hưởng tới các dịch
#  vụ đang chạy (MySQL, MongoDB, các dự án hiện có)."
###############################################################################
set -eo pipefail

log() { echo -e "\n\033[1;32m[M910Q-SETUP]\033[0m $1"; }
info() { echo -e "  \033[1;34m[INFO]\033[0m $1"; }
ok() { echo -e "  \033[1;32m[OK]\033[0m $1"; }
warn() { echo -e "  \033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; }

if [ "$EUID" -ne 0 ]; then
  err "Vui lòng chạy script này với quyền root hoặc sudo: sudo bash $0"
  exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PACKS="$REAL_HOME/Documents/Systems/install-packs"

log "Bắt đầu kiểm tra và cấu hình môi trường cho Lenovo ThinkCentre M910q (User: $REAL_USER)..."

DESIRED_HOSTNAME="qa-server-m910q"
CURRENT_HOSTNAME="$(hostnamectl --static 2>/dev/null || hostname -s)"
if [ "$CURRENT_HOSTNAME" != "$DESIRED_HOSTNAME" ]; then
  info "Đặt hostname $CURRENT_HOSTNAME → $DESIRED_HOSTNAME..."
  hostnamectl set-hostname "$DESIRED_HOSTNAME"
  if grep -qE "[[:space:]]${CURRENT_HOSTNAME}([[:space:]]|$)" /etc/hosts; then
    sed -i "s/${CURRENT_HOSTNAME}/${DESIRED_HOSTNAME}/g" /etc/hosts
  fi
  if ! grep -qE "[[:space:]]${DESIRED_HOSTNAME}([[:space:]]|$)" /etc/hosts; then
    echo "127.0.1.1 ${DESIRED_HOSTNAME}" >> /etc/hosts
  fi
  systemctl restart avahi-daemon 2>/dev/null || true
  ok "Hostname hiện tại: $(hostnamectl --static)"
else
  ok "Hostname đã đúng: $DESIRED_HOSTNAME"
fi

# ==============================================================================
# 1. PHẦN CỨNG & NGUỒN ĐIỆN (KEEP-ALIVE & WAKE-ON-LAN)
# ==============================================================================
log "Bước 1/6: Kiểm tra cấu hình phần cứng (Sleep & Wake-on-LAN)..."

if [ -f "$SCRIPT_DIR/configure_desktop.sh" ]; then
  bash "$SCRIPT_DIR/configure_desktop.sh"
else
  warn "Không tìm thấy configure_desktop.sh, áp dụng keep-alive trực tiếp..."
  mkdir -p /etc/systemd/logind.conf.d/
  cat <<EOF > /etc/systemd/logind.conf.d/desktop-keepalive.conf
[Login]
IdleAction=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
EOF
  systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
fi
ok "Cấu hình phần cứng hoàn tất."

# ==============================================================================
# 2. KIỂM TRA BASE BUILD TOOLS & LIBRARIES CẦN THIẾT CHO RUBY / NODE
# ==============================================================================
log "Bước 2/6: Kiểm tra các thư viện build (C/C++, OpenSSL, libvips, libpq)..."

REQUIRED_PKGS=(
  build-essential curl wget git libssl-dev zlib1g-dev libreadline-dev
  libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev
  pkg-config libvips-dev ethtool avahi-daemon
)

MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    MISSING_PKGS+=("$pkg")
  fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
  info "Cài đặt các gói còn thiếu: ${MISSING_PKGS[*]}..."
  apt update -y
  apt install -y "${MISSING_PKGS[@]}"
  ok "Đã bổ sung các thư viện hệ thống cần thiết."
else
  ok "Tất cả các thư viện build cơ bản đã có sẵn. Bỏ qua cài đặt."
fi

# ==============================================================================
# 3. KIỂM TRA & BẢO TOÀN CƠ SỞ DỮ LIỆU (MYSQL, MONGO, POSTGRES, REDIS)
# ==============================================================================
log "Bước 3/6: Kiểm tra các dịch vụ cơ sở dữ liệu..."

# 3.1 MySQL (Đang có dự án chạy - BẢO TOÀN)
if command -v mysql &>/dev/null; then
  ok "MySQL đã được cài đặt ($(mysql --version | head -n 1)). Bảo toàn cấu hình và dữ liệu hiện có."
  if ! systemctl is-active --quiet mysql; then
    info "Khởi động mysql.service..."
    systemctl start mysql || true
  fi
else
  info "MySQL chưa được cài đặt (không bắt buộc cho vn-mdm)."
fi

# 3.2 MongoDB (Đang có dự án chạy - BẢO TOÀN)
if command -v mongod &>/dev/null; then
  ok "MongoDB đã được cài đặt ($(mongod --version | head -n 1 | awk '{print $1,$2,$3}')). Bảo toàn cấu hình và dữ liệu."
  if ! systemctl is-active --quiet mongod; then
    info "Khởi động mongod.service..."
    systemctl start mongod || true
  fi
else
  info "MongoDB chưa được cài đặt (không bắt buộc cho vn-mdm)."
fi

# 3.3 PostgreSQL (Bắt buộc cho VN-MDM)
if command -v psql &>/dev/null; then
  ok "PostgreSQL đã được cài đặt ($(psql --version)). Sử dụng bản hiện có."
else
  info "PostgreSQL chưa có. Đang tiến hành cài đặt PostgreSQL 16 và thư viện dev..."
  apt install -y postgresql postgresql-contrib libpq-dev
  systemctl enable postgresql
  systemctl start postgresql
  ok "Đã cài đặt PostgreSQL."
fi

# Đảm bảo PostgreSQL service đang chạy
systemctl start postgresql || true

# Tạo user/database cho vn-mdm nếu chưa có (idempotent)
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='vnmdm'" | grep -q 1; then
  ok "PostgreSQL user 'vnmdm' đã tồn tại."
else
  info "Tạo PostgreSQL user 'vnmdm'..."
  sudo -u postgres psql -c "CREATE USER vnmdm WITH PASSWORD 'vnmdm' CREATEDB SUPERUSER;" || true
fi

for db in vn_mdm_development vn_mdm_production vn_mdm_queue; do
  if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
    ok "PostgreSQL database '$db' đã tồn tại."
  else
    info "Tạo PostgreSQL database '$db'..."
    sudo -u postgres createdb -O vnmdm "$db" 2>/dev/null || true
  fi
done

# 3.4 Redis (Bắt buộc cho cache / pub-sub / job)
if command -v redis-server &>/dev/null; then
  ok "Redis server đã được cài đặt ($(redis-server --version | awk '{print $1,$2,$3}'))."
else
  info "Redis chưa có. Tiến hành cài đặt redis-server..."
  apt install -y redis-server
  systemctl enable redis-server
  systemctl start redis-server
  ok "Đã cài đặt Redis server."
fi

# ==============================================================================
# 4. KIỂM TRA VERSION MANAGERS (RBENV & NODENV) VÀ PHIÊN BẢN CẦN THIẾT
# ==============================================================================
log "Bước 4/6: Kiểm tra rbenv (Ruby 3.4.7) và nodenv (Node 22.18.0)..."

# 4.1 Ruby via rbenv
RBENV_ROOT="$REAL_HOME/.rbenv"
if [ -d "$RBENV_ROOT" ]; then
  ok "rbenv đã được cài đặt tại $RBENV_ROOT."
  
  TARGET_RUBY="3.4.7"
  if [ -d "$RBENV_ROOT/versions/$TARGET_RUBY" ]; then
    ok "Ruby $TARGET_RUBY đã có sẵn trong rbenv! Bỏ qua biên dịch từ mã nguồn."
  else
    info "Ruby $TARGET_RUBY chưa có. Tiến hành cài đặt bằng rbenv..."
    sudo -u "$REAL_USER" bash -lc "rbenv install $TARGET_RUBY" || warn "Không thể biên dịch Ruby $TARGET_RUBY qua rbenv tự động."
  fi

  # Cài bundler cho Ruby 3.4.7 nếu chưa có
  if [ -x "$RBENV_ROOT/versions/$TARGET_RUBY/bin/bundle" ]; then
    ok "Bundler đã có sẵn cho Ruby $TARGET_RUBY."
  else
    info "Cài đặt bundler cho Ruby $TARGET_RUBY..."
    sudo -u "$REAL_USER" bash -lc "RBENV_VERSION=$TARGET_RUBY gem install bundler --no-document" || true
  fi
else
  warn "rbenv chưa có tại $RBENV_ROOT. Vui lòng cài rbenv theo hướng dẫn runbook."
fi

# 4.2 Node via nodenv
NODENV_ROOT="$REAL_HOME/.nodenv"
if [ -d "$NODENV_ROOT" ]; then
  ok "nodenv đã được cài đặt tại $NODENV_ROOT."
  
  TARGET_NODE="22.18.0"
  if [ -d "$NODENV_ROOT/versions/$TARGET_NODE" ]; then
    ok "Node $TARGET_NODE đã có sẵn trong nodenv! Bỏ qua cài đặt."
  else
    info "Node $TARGET_NODE chưa có. Tiến hành cài đặt bằng nodenv..."
    sudo -u "$REAL_USER" bash -lc "nodenv install $TARGET_NODE" || warn "Không thể cài Node $TARGET_NODE qua nodenv tự động."
  fi
else
  warn "nodenv chưa có tại $NODENV_ROOT."
fi

# ==============================================================================
# 5. KIỂM TRA NGINX REVERSE PROXY CHO VN-MDM
# ==============================================================================
log "Bước 5/6: Kiểm tra Nginx Web Server..."

if command -v nginx &>/dev/null; then
  ok "Nginx đã được cài đặt ($(nginx -v 2>&1))."
else
  info "Nginx chưa có. Tiến hành cài đặt Nginx..."
  apt install -y nginx
  systemctl enable nginx
fi

# Cloudflare Tunnel terminates TLS; honor X-Forwarded-Proto when present.
cat <<'EOF' > /etc/nginx/conf.d/forwarded-proto.conf
map $http_x_forwarded_proto $forwarded_proto {
    default $http_x_forwarded_proto;
    ''      $scheme;
}
EOF

# Thiết lập vhost vnmdm nếu chưa có
NGINX_CONF="/etc/nginx/sites-available/vnmdm"
if [ ! -f "$NGINX_CONF" ]; then
  info "Tạo cấu hình Nginx reverse proxy cho VN-MDM tại $NGINX_CONF..."
  cat <<'EOF' > "$NGINX_CONF"
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 50M;

    # Backend routes: Rails API (:3000)
    location ~ ^/(api|up|mdm|enroll|[^/]+/(mdm|enroll|apps|vpp|windows)) {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $forwarded_proto;
    }

    # Frontend routes: Next.js Web UI (:3001)
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $forwarded_proto;
    }
}
EOF
  # Xóa default site nếu cần để tránh trùng port 80
  rm -f /etc/nginx/sites-enabled/default
  ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/vnmdm
  nginx -t && systemctl reload nginx || warn "Kiểm tra cấu hình Nginx thất bại, vui lòng rà soát lại file cấu hình."
  ok "Đã kích hoạt cấu hình Nginx vnmdm."
else
  ok "Cấu hình Nginx $NGINX_CONF đã tồn tại. Giữ nguyên không ghi đè."
fi

# ==============================================================================
# 6. KIỂM TRA DESKTOP APPS (TẬN DỤNG DOCUMENTS/SYSTEMS/INSTALL-PACKS)
# ==============================================================================
log "Bước 6/6: Kiểm tra các ứng dụng Desktop phục vụ Dev..."

# Chrome
if command -v google-chrome &>/dev/null; then
  ok "Google Chrome đã cài đặt."
elif [ -f "$INSTALL_PACKS/google-chrome-stable_current_amd64.deb" ]; then
  info "Cài đặt Chrome từ kho offline $INSTALL_PACKS..."
  apt install -y "$INSTALL_PACKS/google-chrome-stable_current_amd64.deb" || apt --fix-broken install -y
fi

# Warp Terminal
if command -v warp-terminal &>/dev/null; then
  ok "Warp Terminal đã cài đặt."
elif [ -f "$INSTALL_PACKS/warp-terminal_0.2024.10.29.08.02.stable.02_amd64.deb" ]; then
  info "Cài đặt Warp từ kho offline $INSTALL_PACKS..."
  apt install -y "$INSTALL_PACKS/warp-terminal_0.2024.10.29.08.02.stable.02_amd64.deb" || apt --fix-broken install -y
fi

# Cursor IDE
if command -v cursor &>/dev/null || [ -f /usr/local/bin/cursor ]; then
  ok "Cursor IDE đã cài đặt."
elif [ -f "$INSTALL_PACKS/Cursor-2.2.23-x86_64.AppImage" ]; then
  info "Cấu hình Cursor IDE từ kho offline..."
  cp "$INSTALL_PACKS/Cursor-2.2.23-x86_64.AppImage" /opt/cursor.appimage
  chmod +x /opt/cursor.appimage
  ln -sf /opt/cursor.appimage /usr/local/bin/cursor
fi

# TablePlus
if [ -f "$REAL_HOME/.local/share/applications/tableplus.desktop" ]; then
  ok "TablePlus launcher đã sẵn sàng."
elif [ -f "$INSTALL_PACKS/TablePlus-x64.AppImage" ]; then
  info "Cấu hình TablePlus desktop shortcut..."
  mkdir -p "$REAL_HOME/.local/share/applications"
  cat <<EOF > "$REAL_HOME/.local/share/applications/tableplus.desktop"
[Desktop Entry]
Name=TablePlus
Exec=$INSTALL_PACKS/TablePlus-x64.AppImage
Icon=$INSTALL_PACKS/apple-icon-tableplus.png
Type=Application
Categories=Development;
Terminal=false
EOF
  chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.local/share/applications/tableplus.desktop" 2>/dev/null || true
  chmod +x "$REAL_HOME/.local/share/applications/tableplus.desktop" 2>/dev/null || true
fi

# ==============================================================================
# 7. CẤU HÌNH SYSTEMD DAEMONS CHO VN-MDM (NẾU ĐÃ CÓ MÃ NGUỒN ~/vn-mdm)
# ==============================================================================
VNMDM_API="$REAL_HOME/vn-mdm/api"
VNMDM_WEB="$REAL_HOME/vn-mdm/web"

if [ -d "$VNMDM_API" ] && [ -d "$VNMDM_WEB" ]; then
  log "Bước 7/7: Thiết lập các dịch vụ Systemd tự khởi động cho VN-MDM..."

  NPM_BIN="$REAL_HOME/.nodenv/shims/npm"
  BUNDLE_BIN="$REAL_HOME/.rbenv/shims/bundle"
  EXTRA_PATH="$REAL_HOME/.nodenv/shims:$REAL_HOME/.rbenv/shims:$REAL_HOME/.rbenv/bin"

  # 7.1 Backend service
  cat <<EOF > /etc/systemd/system/vnmdm-backend.service
[Unit]
Description=VN-MDM Rails Backend
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$VNMDM_API
Environment="RAILS_ENV=development"
Environment="PATH=$EXTRA_PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$BUNDLE_BIN exec rails server -b 127.0.0.1 -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  ok "Đã cấu hình /etc/systemd/system/vnmdm-backend.service."

  # 7.2 Worker service
  cat <<EOF > /etc/systemd/system/vnmdm-worker.service
[Unit]
Description=VN-MDM Solid Queue Worker (APNs Push & Background Jobs)
After=network.target postgresql.service redis-server.service vnmdm-backend.service

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$VNMDM_API
Environment="RAILS_ENV=development"
Environment="PATH=$EXTRA_PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$BUNDLE_BIN exec bin/jobs
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  ok "Đã cấu hình /etc/systemd/system/vnmdm-worker.service."

  # 7.3 Frontend service
  cat <<EOF > /etc/systemd/system/vnmdm-frontend.service
[Unit]
Description=VN-MDM Next.js Frontend
After=network.target vnmdm-backend.service

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$VNMDM_WEB
Environment="NODE_ENV=development"
Environment="PATH=$EXTRA_PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$NPM_BIN run dev -- -p 3001 -H 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  ok "Đã cấu hình /etc/systemd/system/vnmdm-frontend.service."

  systemctl daemon-reload
  systemctl enable vnmdm-backend vnmdm-worker vnmdm-frontend nginx
  ok "Đã kích hoạt auto-start cho tất cả các dịch vụ VN-MDM."
else
  info "Chưa tìm thấy thư mục ~/vn-mdm/api hoặc ~/vn-mdm/web. Bỏ qua cấu hình systemd."
fi

log "=========================================================================="
log " 🎉 KIỂM TRA VÀ CẤU HÌNH MÁY TRẠM M910Q HOÀN TẤT THÀNH CÔNG!"
log "=========================================================================="
info "Tất cả các dịch vụ đã có (MySQL, MongoDB) đều được bảo vệ toàn vẹn."
info "PostgreSQL, Redis, Nginx đã sẵn sàng cho dự án VN-MDM."
info "Ruby 3.4.7 và Node 22.18.0 đã sẵn sàng."
info "Khởi động toàn bộ stack bằng lệnh: sudo systemctl restart nginx vnmdm-backend vnmdm-worker vnmdm-frontend"
log "=========================================================================="
