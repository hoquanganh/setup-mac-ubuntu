# Remote Access Tools — Danh Sách Cài Đặt

Tài liệu này liệt kê các công cụ kết nối từ xa cho server **VN-MDM** trên MacBook Pro. Script `setup_macbook_ubuntu.sh` (Phase 4) tự động cài **Tailscale** và **ngrok**; các bước xác thực cần làm thủ công sau khi cài.

## So Sánh Nhanh

| Tool | Mục đích | Ai truy cập được | Cần mở port Router? |
|---|---|---|---|
| **Avahi** (`.local`) | Truy cập trong cùng WiFi | Mọi thiết bị cùng LAN | Không |
| **OpenSSH** | SSH terminal | Máy có quyền truy cập mạng | Chỉ nếu expose ra Internet |
| **Tailscale** | VPN riêng giữa thiết bị của bạn | Chỉ thiết bị đã đăng nhập cùng tài khoản | Không |
| **ngrok** | Tunnel công khai qua Internet | Bất kỳ ai có URL (hoặc domain reserved) | Không |

**Khuyến nghị:**
- Dùng hàng ngày / SSH / truy cập riêng tư → **Tailscale**
- Chia sẻ demo tạm thời cho người ngoài mạng → **ngrok**
- Trong nhà cùng WiFi → **`qa-MacBookPro15-2.local`**

---

## 1. Avahi (mDNS — truy cập local)

Đã cài sẵn trên server. Cho phép truy cập bằng tên `.local` thay vì IP.

```bash
sudo apt install -y avahi-daemon
sudo systemctl enable --now avahi-daemon
```

| Mục đích | Lệnh / URL |
|---|---|
| Web | `http://qa-MacBookPro15-2.local` |
| SSH | `ssh qa@qa-MacBookPro15-2.local` |

---

## 2. OpenSSH

Đã cài sẵn trên server.

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo ufw allow OpenSSH
```

---

## 3. Tailscale (VPN — truy cập riêng tư từ xa)

### Cài đặt (tự động qua script hoặc thủ công)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### Xác thực (bắt buộc, làm một lần)

```bash
sudo tailscale up
# Mở link hiện ra trên trình duyệt, đăng nhập Google/GitHub
```

### Sử dụng

```bash
tailscale status          # xem IP ảo (dạng 100.x.y.z)
tailscale ip -4           # chỉ in IP
```

| Mục đích | Lệnh / URL |
|---|---|
| Web | `http://100.x.y.z` |
| SSH | `ssh qa@100.x.y.z` |

Trên máy/điện thoại khác: cài app [Tailscale](https://tailscale.com/download) và đăng nhập **cùng tài khoản**.

---

## 4. ngrok (Tunnel công khai — demo / chia sẻ tạm)

Dùng khi cần cho người **không có Tailscale** truy cập VN-MDM qua Internet (ví dụ demo cho khách, test từ 4G).

### Cài đặt (tự động qua script hoặc thủ công)

```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update
sudo apt install -y ngrok
```

### Xác thực (bắt buộc, làm một lần)

1. Đăng ký tài khoản tại [ngrok.com](https://ngrok.com/)
2. Lấy authtoken tại [dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
3. Chạy:

```bash
ngrok config add-authtoken <YOUR_AUTHTOKEN>
```

### Expose VN-MDM (Nginx port 80)

VN-MDM chạy qua Nginx reverse proxy trên port 80 — tunnel port này để cả frontend lẫn API hoạt động:

```bash
ngrok http 80
```

ngrok sẽ in URL dạng `https://xxxx.ngrok-free.app` — gửi link này cho người cần truy cập.

### URL cố định (tuỳ chọn, gói trả phí)

Trong [ngrok Dashboard](https://dashboard.ngrok.com/) → **Domains** → reserve domain, rồi:

```bash
ngrok http --domain=your-name.ngrok-free.app 80
```

### Chạy nền với systemd (tuỳ chọn)

Tạo `/etc/systemd/system/ngrok-vnmdm.service`:

```ini
[Unit]
Description=ngrok tunnel for VN-MDM (port 80)
After=network-online.target nginx.service
Wants=network-online.target

[Service]
Type=simple
User=qa
ExecStart=/usr/bin/ngrok http 80 --log=stdout
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ngrok-vnmdm
journalctl -u ngrok-vnmdm -f
```

> **Lưu ý bảo mật:** ngrok tạo URL công khai. Chỉ bật khi cần demo; tắt khi không dùng (`Ctrl+C` hoặc `sudo systemctl stop ngrok-vnmdm`).

---

## Checklist Sau Khi Cài Máy Mới

- [ ] Avahi chạy → truy cập được `http://qa-MacBookPro15-2.local`
- [ ] SSH hoạt động → `ssh qa@qa-MacBookPro15-2.local`
- [ ] Tailscale cài + `sudo tailscale up` → truy cập được qua IP `100.x.y.z`
- [ ] ngrok cài + `ngrok config add-authtoken` → `ngrok http 80` ra URL công khai
- [ ] VN-MDM services active → `sudo systemctl status vnmdm-backend vnmdm-frontend nginx`
