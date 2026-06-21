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

Vì IP tĩnh của nhà không cố định và khó cấu hình mở port Router, giải pháp tối ưu, an toàn và dễ nhất là sử dụng mạng riêng ảo **Tailscale**:

1. Mở link này trên trình duyệt để xác thực Server với tài khoản Tailscale của bạn: [https://login.tailscale.com/a/c5c5b401a86f](https://login.tailscale.com/a/c5c5b401a86f) (Đăng nhập bằng Google/GitHub).
2. Cài đặt app **Tailscale** trên máy tính khác hoặc điện thoại của bạn và đăng nhập cùng tài khoản đó.
3. Trong app Tailscale, bạn sẽ thấy thiết bị tên `qa-MacBookPro15-2` kèm theo một IP cố định (ví dụ `100.x.y.z`).
4. Từ nay về sau, ở bất kỳ đâu có Internet, bạn có thể:
   - Truy cập Web: Vào trình duyệt gõ IP Tailscale `http://100.x.y.z`
   - SSH vào máy: `ssh qa@100.x.y.z`
