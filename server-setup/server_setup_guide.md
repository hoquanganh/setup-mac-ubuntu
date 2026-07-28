# 🖥️ Hướng dẫn Setup Server 24/7 (MacBook Pro - Ubuntu 26.04)

Tài liệu này tổng hợp toàn bộ quá trình thiết lập chiếc MacBook Pro thành một Web Server hoạt động liên tục 24/7, phục vụ dự án `vn-mdm` với Rails (Backend) và Next.js (Frontend). Hệ thống có thể tự động chạy lại khi khởi động máy.

## 1. Thông Tin Mạng & Truy cập

Hệ thống có thể được truy cập từ bất kỳ thiết bị nào cùng mạng WiFi:
*   **Truy cập Website:** `http://qa-MacBookPro15-2.local` hoặc `http://172.26.25.62`
*   **SSH vào Server:** `ssh qa@172.26.25.62` hoặc `ssh qa@qa-MacBookPro15-2.local` (Yêu cầu mật khẩu máy).

## 2. Kiến trúc Hệ Thống

```mermaid
graph TD
    User([Người dùng / Thiết bị]) -->|HTTP :80| Nginx[Nginx Reverse Proxy]
    Nginx -->|/api, /mdm, /enroll, /up| Rails[Rails Backend :3000]
    Nginx -->|/ (Các đường dẫn khác)| NextJS[Next.js Frontend :3001]
    Rails --> Postgres[(PostgreSQL)]
    Rails --> Redis[(Redis)]
```

## 3. Cấu Hình Năng Lượng (Power Management)
Để cho phép gập màn hình (close lid) mà máy không bị sleep:
*   Đã chỉnh sửa file `/etc/systemd/logind.conf`:
    *   `HandleLidSwitch=ignore`
    *   `HandleLidSwitchExternalPower=ignore`
    *   `HandleLidSwitchDocked=ignore`
*   Đã mask (vô hiệu hóa) các tính năng sleep: `sleep.target`, `suspend.target`, `hibernate.target`, `hybrid-sleep.target`.

## 4. Các Dịch vụ Đã Cài Đặt (Services)

Tất cả các dịch vụ đã được thiết lập để tự động khởi động cùng hệ thống (`systemd`):

1.  **PostgreSQL & Redis:** Chạy ở chế độ system daemon. Đã tạo user `vnmdm` và password `vnmdm`.
2.  **avahi-daemon:** Để hỗ trợ mDNS (Domain `.local`), giúp kết nối bằng tên `qa-MacBookPro15-2.local` kể cả khi IP bị thay đổi (dynamic IP).
3.  **vnmdm-backend (Rails):**
    *   Thư mục: `~/vn-mdm/api`
    *   Lệnh: `bundle exec rails server -b 127.0.0.1 -p 3000`
    *   Quản lý bằng: `sudo systemctl status vnmdm-backend`
4.  **vnmdm-frontend (Next.js):**
    *   Thư mục: `~/vn-mdm/web`
    *   Lệnh: `npm run dev -- -p 3001 -H 127.0.0.1`
    *   Quản lý bằng: `sudo systemctl status vnmdm-frontend`
5.  **Nginx (Reverse Proxy):**
    *   File cấu hình: `/etc/nginx/sites-available/vnmdm`
    *   Quản lý bằng: `sudo systemctl status nginx`

## 5. Hướng Dẫn Vận Hành Cơ Bản

*   **Xem logs Backend:** `journalctl -u vnmdm-backend -f`
*   **Xem logs Frontend:** `journalctl -u vnmdm-frontend -f`
*   **Restart Backend (khi sửa code):** `sudo systemctl restart vnmdm-backend`
*   **Restart Frontend:** `sudo systemctl restart vnmdm-frontend`
*   **Cập nhật môi trường Frontend:** Sửa `~/vn-mdm/web/.env.local` (đã xoá domain trong `NEXT_PUBLIC_API_URL` để dùng chung domain với frontend thông qua Nginx).

## 6. Ghi Chú Khi Triển Khai Thực Tế Lâu Dài
*   Hiện tại Next.js đang chạy ở chế độ `npm run dev`. Đối với môi trường thực tế hoàn chỉnh, nên chạy `npm run build` và đổi lệnh thành `npm run start`.
*   Tương tự, Rails đang chạy với `RAILS_ENV=development`.
*   Tất cả tài liệu setup tự động (script) và lịch sử thao tác đã được lưu tại `~/Documents/Ubuntu_install/server-setup/`.

## 7. Truy Cập Từ Xa (Khác mạng WiFi / Qua 4G)

Xem danh sách đầy đủ tại **`remote_access_tools.md`**. Tóm tắt hai phương án chính:

### Tailscale — VPN riêng (khuyến nghị)

1. Cài đặt (nếu chưa có): `curl -fsSL https://tailscale.com/install.sh | sh`
2. Xác thực: `sudo tailscale up` → đăng nhập Google/GitHub trên trình duyệt.
3. Trên máy khác: cài app Tailscale, đăng nhập cùng tài khoản.
4. Truy cập qua IP ảo `100.x.y.z`:
   - Web: `http://100.x.y.z`
   - SSH: `ssh qa@100.x.y.z`

### ngrok — Tunnel công khai (demo / chia sẻ tạm)

Dùng khi cần cho người không có Tailscale truy cập VN-MDM qua Internet.

1. Cài đặt:
   ```bash
   curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
     | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
   echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
     | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install -y ngrok
   ```
2. Lấy authtoken tại [dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
3. Xác thực: `ngrok config add-authtoken <YOUR_AUTHTOKEN>`
4. Expose VN-MDM (Nginx port 80): `ngrok http 80`
5. Gửi URL `https://xxxx.ngrok-free.app` cho người cần truy cập.

> **Lưu ý:** ngrok tạo URL công khai — chỉ bật khi cần demo, tắt khi không dùng.
