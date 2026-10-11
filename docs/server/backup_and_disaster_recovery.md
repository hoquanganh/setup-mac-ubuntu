# 💾 Quy Trình Sao Lưu & Khôi Phục Thảm Họa (Backup & Disaster Recovery)

Tài liệu này hướng dẫn chi tiết quy trình **sao lưu định kỳ (Backup)**, **cảnh báo sự cố qua Email**, và **khôi phục thảm họa 1-click (Disaster Recovery)** cho máy chủ **Lenovo ThinkCentre M910q** (hoặc các máy chủ Ubuntu chạy nền tảng **VN-MDM**).

---

## 📌 1. Danh Mục Thành Phần Được Sao Lưu (Backup Inventory)

Khi chạy kịch bản `sudo bash bin/backup_system_data.sh`, toàn bộ các thành phần quan trọng sau sẽ được tự động đóng gói vào một file nén dạng `backup_m910q_YYYYMMDD_HHMMSS.tar.gz` kèm mã checksum `.sha256`:

| Hạng mục | Đường dẫn nguồn trên hệ thống | Ý nghĩa & Tầm quan trọng |
|---|---|---|
| **Cơ sở dữ liệu PostgreSQL** | Database `vn_mdm_*` (`vn_mdm_development`, `vn_mdm_development_queue`, `vn_mdm_production`,...) | Dữ liệu thiết bị đã Enroll, tài khoản Admin, cấu hình Profile MDM, lịch sử gửi lệnh. |
| **Phân quyền Database** | `pg_globals.sql` | Danh sách User (`vnmdm`), mật khẩu và quyền hạn trong PostgreSQL. |
| **Rails Secret & Master Key** | `~/vn-mdm/api/config/master.key`<br>`~/vn-mdm/api/config/credentials.yml.enc` | **CỰC KỲ QUAN TRỌNG:** Chìa khóa giải mã toàn bộ credentials bí mật của Rails API. Mất key này sẽ không thể đọc lại credentials. |
| **Tệp tải lên (ActiveStorage)** | `~/vn-mdm/api/storage/` | Logo doanh nghiệp, file chứng chỉ tải lên, file payload profile. |
| **Landing Page Secrets** | `/etc/vn-mdm-landing/app.env`<br>`/etc/vn-mdm-landing/tunnel.env` | Cấu hình SMTP Gmail, Secret Token của Landing, Token Cloudflare Tunnel cho landing. |
| **Leads Khách hàng Landing** | `/var/lib/vn-mdm-landing/leads.jsonl` | Danh sách thông tin liên hệ của khách hàng đăng ký trên trang landing. |
| **Mạng & Tunnel** | `/var/lib/tailscale/tailscaled.state`<br>`/etc/cloudflared/`<br>`~/.cloudflared/` | Khóa xác thực node Tailscale (giữ nguyên IP 100.x mà không cần login lại) và cấu hình Cloudflare Tunnel. |
| **Dịch vụ Hệ thống & Web** | `/etc/nginx/sites-available/`<br>`/etc/nginx/conf.d/`<br>`/etc/systemd/system/vnmdm*`<br>`/etc/systemd/system/vn-mdm-landing*`<br>`/etc/systemd/system/cloudflared*` | Toàn bộ cấu hình VirtualHost Nginx và các unit file tự khởi động của Systemd. |
| **Khóa SSH & Cloud CLI** | `~/.ssh/`<br>`~/.aws/`<br>`~/.azure/`<br>`~/.kube/config` | Toàn bộ SSH Private Keys kết nối GitHub/Server, token đăng nhập Azure/AWS/Kube. |
| **Môi trường Shell cá nhân** | `~/.zshrc`, `~/.p10k.zsh`, `~/.zsh_history`<br>`~/.bashrc`, `~/.bash_history`<br>`~/.gitconfig`, `~/.viminfo` | Toàn bộ lịch sử lệnh (command history), theme terminal, cấu hình alias và git. |

---

## ⚡ 2. Cách Thực Hiện Sao Lưu (Backup Execution)

### 2.1. Sao Lưu Thủ Công (1-Click)
Mở terminal và chạy lệnh:

```bash
cd ~/dev/setup-mac-ubuntu
sudo bash bin/backup_system_data.sh --notify-email
```

Kịch bản sẽ:
1. Dump toàn bộ database `vn_mdm_*` sang định dạng nén `.dump` và `.sql.gz`.
2. Đóng gói toàn bộ bí mật, leads, storage, ssh, shell configs.
3. Tạo file nén tại `~/backups/backup_m910q_YYYYMMDD_HHMMSS.tar.gz`.
4. Tạo mã băm SHA256 để đảm bảo tính toàn vẹn.
5. Giữ lại **4 bản sao lưu gần nhất** trên đĩa (tự động xóa bản cũ hơn để tiết kiệm dung lượng).
6. Tự động đẩy lên Google Drive (nếu đã cấu hình `rclone`).
7. Gửi email thông báo kết quả thành công qua Gmail.

### 2.2. Sao Lưu Tự Động Hàng Tuần (Systemd Timer)
Hệ thống đã được cài đặt sẵn timer tự động chạy vào **02:00 sáng Chủ Nhật hàng tuần**:
- Service: `/etc/systemd/system/vnmdm-backup.service`
- Timer: `/etc/systemd/system/vnmdm-backup.timer`

Kiểm tra trạng thái timer:
```bash
systemctl list-timers | grep vnmdm-backup
```

---

## ☁️ 3. Thiết Lập Đẩy Bản Sao Lưu Lên Google Drive (rclone)

Hệ thống sử dụng công cụ chuẩn công nghiệp **`rclone`** để đồng bộ file backup lên Google Drive.

### Trạng thái hiện tại:
> [!NOTE]
> **Remote `gdrive:` đã được cấu hình và xác thực thành công!**
> Các bản backup đã và đang tự động đồng bộ trực tiếp lên thư mục:
> `gdrive:Backups/qa-server-m910q/`

### Nếu sau này muốn kết nối lại hoặc đổi tài khoản Google Drive:
Chỉ cần chạy 1 lệnh duy nhất (không cần nhập thủ công từng bước):
```bash
rclone config reconnect gdrive:
```
1. Trình duyệt Chrome sẽ tự động mở trang xác thực tài khoản Google.
2. Chọn tài khoản Google Drive và ấn **"Cho phép / Allow"**.
3. Rclone sẽ tự động lưu token mới và tiếp tục đồng bộ bình thường.

---

## 📧 4. Cơ Chế Cảnh Báo Sự Cố Qua Email (Gmail SMTP)

Hệ thống tích hợp công cụ cảnh báo độc lập [`bin/send_alert_email.py`](file:///home/quanganhho/dev/setup-mac-ubuntu/bin/send_alert_email.py) (sử dụng thư viện chuẩn của Python 3, không cần cài thêm package).

### Cấu hình Email:
Tự động kế thừa thông tin Google App Password có sẵn tại `/etc/vn-mdm-landing/app.env`:
- **SMTP Host:** `smtp.gmail.com` (Port 465 SSL)
- **Tài khoản gửi:** `hoquanganh.bmt@gmail.com`
- **Tài khoản nhận:** `hoquanganh.bmt@gmail.com`

### Các trường hợp kích hoạt cảnh báo:
1. **Khi tiến trình Backup gặp lỗi:** Trap lỗi tự động bắt mã lệnh, số dòng bị lỗi và gửi email đỏ `[ERROR] Weekly Backup FAILED`.
2. **Khi dịch vụ hệ thống bị tắt hoặc chết cổng (Health Monitor):**
   - File giám sát [`bin/health_check.sh`](file:///home/quanganhho/dev/setup-mac-ubuntu/bin/health_check.sh) chạy ngầm mỗi 60 phút (1 tiếng) qua timer `vnmdm-healthcheck.timer`.
   - Giám sát 8 dịch vụ: `vnmdm-backend`, `vnmdm-worker`, `vnmdm-frontend`, `vn-mdm-landing`, `cloudflared`, `cloudflared-landing`, `nginx`, `postgresql`.
   - Giám sát 5 cổng: `3000`, `3001`, `4321`, `80`, `5432`.
   - Giám sát dung lượng ổ cứng (cảnh báo khi dung lượng đĩa > 90%).
   - Nếu phát hiện dịch vụ DOWN, tự động gửi email cảnh báo chi tiết kèm lệnh khắc phục.

Kiểm tra sức khỏe hệ thống thủ công:
```bash
./bin/health_check.sh
```

---

## 🔄 5. Quy Trình Khôi Phục Thảm Họa (Disaster Recovery Runbook)

Giả sử máy M910q bị hỏng ổ cứng hoặc bạn vừa cài mới hoàn toàn một bản Ubuntu 24.04:

### Bước 1: Cài đặt khung môi trường 1-Click
```bash
# 1. Tải repository tự động hoá
git clone https://github.com/hoquanganh/setup-mac-ubuntu.git ~/dev/setup-mac-ubuntu
cd ~/dev/setup-mac-ubuntu

# 2. Cài đặt toàn bộ môi trường nền tảng (Postgres, Redis, Ruby 3.4.7, Node 22, Nginx, rclone, Apps)
sudo bash hardware/desktop-lenovo-m910q/setup_m910q_environment.sh
```

### Bước 2: Clone lại mã nguồn dự án VN-MDM & Landing
```bash
git clone https://github.com/quanganh/vn-mdm.git ~/vn-mdm
# Nếu có landing page:
git clone <URL_REPO_LANDING> ~/vn-mdm-landing
```

### Bước 3: Khôi phục Dữ liệu & Bí mật từ Bản Sao Lưu (1 Lệnh duy nhất)
Copy file backup `.tar.gz` (từ Google Drive hoặc USB) về thư mục `~/backups/`:

```bash
# Chạy script khôi phục tự động (tự động tìm file backup mới nhất nếu không truyền tham số):
sudo bash bin/restore_system_data.sh ~/backups/backup_m910q_20261011_184216.tar.gz
```

Kịch bản sẽ tự động:
1. Kiểm tra mã SHA256 chống hỏng file.
2. Tự nạp lại toàn bộ database `vn_mdm_*` và tài khoản `vnmdm` vào PostgreSQL.
3. Khôi phục `master.key`, `credentials.yml.enc`, thư mục ảnh/file `storage/`.
4. Khôi phục cấu hình landing `/etc/vn-mdm-landing/` và tệp khách hàng `/var/lib/vn-mdm-landing/leads.jsonl`.
5. Khôi phục token `tailscale` (không cần quét mã QR đăng nhập lại).
6. Khôi phục toàn bộ keys `~/.ssh/` (phân quyền chuẩn `0600`), cấu hình AWS, Azure, Kube.
7. Khôi phục lịch sử lệnh và dotfiles (`.zshrc`, `.p10k.zsh`, `.zsh_history`).
8. Nạp lại cấu hình Nginx và các file Systemd unit.

### Bước 4: Khởi động lại toàn bộ dịch vụ
```bash
sudo systemctl restart postgresql nginx
sudo systemctl restart vnmdm-backend vnmdm-worker vnmdm-frontend
sudo systemctl restart vn-mdm-landing cloudflared-landing cloudflared
```

Kiểm tra sức khỏe sau phục hồi:
```bash
./bin/health_check.sh
```
Nếu màn hình hiện `[OK] All core services, endpoints, and disk space are healthy.`, hệ thống đã **khôi phục 100% nguyên trạng** mà không thiếu bất kỳ dữ liệu nào!
