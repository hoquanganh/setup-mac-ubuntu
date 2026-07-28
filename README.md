# MacBook Pro T2 (Ubuntu 26) - Home Server Project

## 🎯 Mục Đích Của Dự Án
Dự án này lưu trữ toàn bộ tài liệu, script, và cấu hình để tái sử dụng lại (re-provision) một chiếc MacBook Pro 2018 (Chip T2) đã được cài đặt Ubuntu 26.04 LTS. Mục đích cuối cùng là biến chiếc Laptop này thành một Web Server hoạt động liên tục 24/7 để chạy dự án **VN-MDM** (gồm Rails Backend và Next.js Frontend) trong môi trường mạng gia đình.

## 📋 Các Nhiệm Vụ Chính Đã Hoàn Thành
1. **Cài đặt Hệ điều hành & Driver:** Cài đặt Ubuntu 26.04 lên phần cứng đặc thù của Apple (MacBook Pro 15,2) và khắc phục các vấn đề tương thích driver (Bàn phím, Touchpad, Âm thanh, Bluetooth, và đặc biệt là card WiFi Broadcom).
2. **Tối ưu Server:** Thiết lập Power Management (cho phép gập màn hình không bị sleep), thiết lập SSH Server.
3. **Triển khai Hệ thống (CI/CD Local):** Thiết lập môi trường chạy ứng dụng (`Ruby`, `Node.js`, `PostgreSQL`, `Redis`), cấu hình `Nginx` Reverse Proxy, và tạo `systemd` services để duy trì uptime 24/7.
4. **Kết Nối Từ Xa:** Cấu hình **Tailscale** (VPN riêng) và **ngrok** (tunnel công khai) để truy cập server từ bất kỳ đâu mà không cần IP tĩnh hay mở port Router.

---

## 📚 Hướng Dẫn Từng Phần (Tham Khảo Nhanh)

### 1. Cài Đặt Ubuntu & Xử Lý Driver (MacBook T2)
Vì phần cứng T2 của Apple rất đặc thù, các script và tài liệu hướng dẫn cài đặt driver gốc được lưu trữ trực tiếp tại thư mục gốc của dự án này:
*   📜 **`t2_macbook_ubuntu_setup_guide.md`**: Tài liệu Hướng dẫn chi tiết từng bước cách cài Ubuntu và fix lỗi driver cho dòng máy MacBook T2.
*   🚀 **`setup_macbook_ubuntu.sh`**: Script tự động hóa cài đặt các dependencies, driver (Keyboard, Touchpad, Audio, Wi-Fi, Vim, Zsh...) và remote access tools (Tailscale, ngrok).
*   📑 **`Install ubuntu 26 04 3613a62bb7ec80d69ae9f4c19a3c90c9.md`**: Ghi chú cá nhân chi tiết trong lúc cài đặt máy ban đầu.

### 2. Thiết Lập Môi Trường Server & Ứng Dụng (vn-mdm)
Mọi tài liệu liên quan đến cấu hình hệ thống web server (sau khi máy đã nhận đủ driver) được đặt trong thư mục `server-setup/`:
*   📘 **`server-setup/server_setup_guide.md`**: Tài liệu **QUAN TRỌNG NHẤT** hướng dẫn tổng quan về kiến trúc Nginx, Systemd, và cách ứng dụng `~/vn-mdm` đang hoạt động. Bạn nên đọc file này để hiểu cách vận hành.
*   🌐 **`server-setup/remote_access_tools.md`**: Danh sách và hướng dẫn cài đặt các tool kết nối từ xa (Avahi, SSH, Tailscale, ngrok).
*   📝 **`server-setup/commands_history.md`**: Lịch sử chi tiết toàn bộ các lệnh CLI đã chạy để cài đặt Nginx, PostgreSQL, Redis và Systemd. Cực kỳ hữu ích nếu bạn cần cài lại máy từ đầu.
*   ⚙️ **Các file cấu hình chuẩn:** `vnmdm.nginx.conf`, `vnmdm-frontend.service`, `vnmdm-backend.service` là các file config gốc đã được đẩy vào `/etc/nginx` và `/etc/systemd`.

### 3. Vận Hành Ứng Dụng Chạy Nền 24/7
Dự án **VN-MDM** (nằm ở `~/vn-mdm`) đã được daemonize bằng `systemd`. Máy tự động chạy các services sau khi khởi động:
*   **Backend (Rails - Port 3000):** `sudo systemctl status vnmdm-backend`
*   **Frontend (Next.js - Port 3001):** `sudo systemctl status vnmdm-frontend`
*   **Reverse Proxy (Nginx - Port 80):** `sudo systemctl status nginx`

### 4. Hướng Dẫn Kết Nối (Local & Remote)

#### Kết nối cùng mạng WiFi (Local)
Do máy cài đặt `avahi-daemon`, IP tĩnh không còn bắt buộc. Bạn có thể truy cập bằng tên miền nội bộ (`.local`):
*   **Web Frontend:** Truy cập `http://qa-MacBookPro15-2.local` trên trình duyệt.
*   **SSH Terminal:** `ssh qa@qa-MacBookPro15-2.local`

#### Kết nối từ xa (Khác mạng, 4G, v.v...)

**Tailscale** — VPN riêng (khuyến nghị cho truy cập hàng ngày):
1.  Cài và xác thực trên Server: `sudo tailscale up`
2.  Tải app Tailscale trên máy/điện thoại khác, đăng nhập cùng tài khoản.
3.  Dùng IP ảo `100.x.y.z` để SSH (`ssh qa@100.x.y.z`) hoặc truy cập Web (`http://100.x.y.z`).

**ngrok** — Tunnel công khai (cho demo / chia sẻ tạm):
1.  Lấy authtoken tại [dashboard.ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken)
2.  `ngrok config add-authtoken <token>`
3.  `ngrok http 80` → nhận URL dạng `https://xxxx.ngrok-free.app`

Chi tiết đầy đủ: **`server-setup/remote_access_tools.md`**
