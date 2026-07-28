# 🚀 Quickstart Guide: Home Server Setup

Chào mừng bạn đến với dự án Home Server. Hướng dẫn này giúp bạn cài đặt server chỉ trong 5 phút.

## 📋 Yêu Cầu Ban Đầu
1. Máy đã cài sẵn hệ điều hành **Ubuntu 22.04 / 24.04 / 26.04 LTS**.
2. Kết nối Internet (Wi-Fi hoặc cáp LAN).
3. Quyền `sudo` trên máy.

---

## ⚡ Cài Đặt 1-Click (Tự Động)

Mở Terminal và chạy duy nhất lệnh sau:

```bash
cd ~/Documents/Ubuntu_install # Hoặc thư mục bạn clone repo
sudo ./bin/setup.sh --auto
```

### Script sẽ tự động thực hiện:
1. 🔍 **Phát hiện phần cứng:** (Nếu là MacBook T2 chip -> cài driver bàn phím, trackpad, Wi-Fi; nếu là Laptop -> tắt chế độ ngủ khi gập màn hình).
2. 🛠️ **Cài đặt công cụ hệ thống:** Vim, Zsh, Chrome, Git, Build tools.
3. 🗄️ **Cài đặt Database:** PostgreSQL 18, Redis 7, MySQL, MongoDB 7.
4. ⚙️ **Cài đặt Môi trường:** Node.js 22, Ruby 3.3.6 (rbenv), Docker.
5. 🌐 **Cài đặt Web Server & Remote:** Nginx Reverse Proxy, UFW Firewall, Avahi mDNS (`.local`), Tailscale VPN, ngrok.
6. 🚀 **Deploy Ứng dụng:** Tự động chạy dự án `vn-mdm` (Rails API :3000 + Next.js Web :3001 qua Nginx :80).

---

## 🔗 Truy Cập Sau Khi Cài Đặt

### 1. Trong cùng mạng Wi-Fi (Local Network)
- **Web App:** [http://qa-MacBookPro15-2.local](http://qa-MacBookPro15-2.local) (hoặc IP máy `http://192.168.x.x`)
- **SSH:** `ssh qa@qa-MacBookPro15-2.local`

### 2. Từ xa qua Internet (VPN Tailscale)
1. Chạy lệnh kích hoạt Tailscale:
   ```bash
   sudo tailscale up
   ```
2. Đăng nhập ứng dụng Tailscale trên điện thoại / máy tính khác với cùng tài khoản.
3. Truy cập Web hoặc SSH thông qua IP ảo `100.x.y.z`.

---

## 📂 Cấu Trúc Thư Mục Dự Án

```
├── bin/
│   └── setup.sh                 # Script chạy chính tự động
├── hardware/                    # Driver & Cấu hình phần cứng (T2 Mac, Laptop power)
├── core/                        # Script cài đặt base system, DBs, runtimes, nginx
├── apps/                        # Cấu hình deploy ứng dụng (VN-MDM, Templates)
└── docs/                        # Tài liệu chi tiết cho người dùng
```
