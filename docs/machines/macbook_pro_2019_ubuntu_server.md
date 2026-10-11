# 💻 Machine Runbook: MacBook Pro 2019 (T2) — 24/7 Ubuntu Server

Tài liệu này lưu trữ toàn bộ cấu hình chuẩn của chiếc máy hiện tại: **Apple MacBook Pro 15-inch 2019 (Chip T2, Model MacBookPro15,2)** chạy **Ubuntu Linux**. Máy đóng vai trò là Web Server hoạt động liên tục 24/7, cung cấp dịch vụ cho dự án **VN-MDM** (Backend Rails, Frontend Next.js, Solid Queue Worker, Nginx reverse proxy, ngrok HTTPS tunnel).

---

## ⚡ 1-Click Khôi Phục Hoàn Toàn (Zero-Thought Restore)

Sau khi cài mới Ubuntu trên chiếc MacBook này, bạn chỉ cần mở Terminal và chạy duy nhất lệnh sau:

```bash
git clone https://github.com/hoquanganh/setup-mac-ubuntu.git ~/Documents/Ubuntu_install
cd ~/Documents/Ubuntu_install
sudo ./bin/restore_current_machine.sh
```

Hoặc thông qua master script:
```bash
sudo ./bin/setup.sh --platform=ubuntu --hardware=t2-mac --profile=server-247 --app=vn-mdm --app-mode=native --auto
```

Script sẽ tự động hoàn tất 100% mọi thứ:
1. **Phần cứng T2:** Cài kernel `linux-t2`, trích xuất firmware Wi-Fi/Bluetooth từ máy chủ Apple, kích hoạt bàn phím, trackpad và audio.
2. **Nguồn điện:** Chống sleep khi gập nắp máy (`HandleLidSwitch=ignore`, mask toàn bộ `sleep.target`, `suspend.target`).
3. **Cơ sở dữ liệu:** Cài đặt và cấu hình PostgreSQL (`vnmdm` / `vnmdm`) và Redis.
4. **Môi trường chạy:** Node.js 22, Ruby (rbenv), Docker.
5. **Mạng nội bộ:** Cài đặt `avahi-daemon` với tên miền `qa-MacBookPro15-2.local`.
6. **Mạng từ xa:** Cài đặt Tailscale và OpenSSH.
7. **Web Server & Firewall:** Cấu hình Nginx reverse proxy trên cổng 80 và mở UFW.
8. **Dự án VN-MDM:** Clone repo, cài đặt gem, build frontend, cài 4 dịch vụ systemd (`vnmdm-backend`, `vnmdm-worker`, `vnmdm-frontend`, `ngrok-vnmdm`).

---

## 🌐 Thông Tin Truy Cập Máy Hiện Tại

- **WiFi nội bộ (LAN):**
  - Website: `http://qa-MacBookPro15-2.local` hoặc `http://172.26.25.62`
  - SSH: `ssh qa@qa-MacBookPro15-2.local`
- **Mạng riêng Tailscale (VPN):**
  - IP ảo: `http://100.x.y.z`
  - SSH: `ssh qa@100.x.y.z`
- **Công khai qua ngrok (Internet / Thiết bị di động bên ngoài):**
  - URL HTTPS tự động cập nhật qua dịch vụ `ngrok-vnmdm.service`.

---

## 🏗️ Kiến Trúc Dịch Vụ Hệ Thống

```mermaid
graph TD
    Client[Người dùng / Thiết bị iOS] -->|Port 80 / HTTPS ngrok| Nginx[Nginx Reverse Proxy]
    
    subgraph Routing trên Nginx
        Nginx -->|/api, /mdm, /enroll, /up| BE[Rails API :3000]
        Nginx -->|/| FE[Next.js Web :3001]
    end

    subgraph Background Processing
        BE --> Postgres[(PostgreSQL 16)]
        BE --> Redis[(Redis 7)]
        Worker[Solid Queue Worker] --> BE
    end
```

---

## 🛠️ Lệnh Quản Lý Dịch Vụ Hàng Ngày

```bash
# Kiểm tra trạng thái toàn bộ dịch vụ
sudo systemctl status nginx vnmdm-backend vnmdm-worker vnmdm-frontend ngrok-vnmdm

# Xem logs trực tiếp
journalctl -u vnmdm-backend -f
journalctl -u vnmdm-worker -f
journalctl -u vnmdm-frontend -f
journalctl -u ngrok-vnmdm -f

# Khởi động lại dịch vụ
sudo systemctl restart vnmdm-backend
sudo systemctl restart vnmdm-frontend
```

---

## ⌨️ Cấu Hình Trackpad, Bàn Phím & Bộ Gõ Tiếng Việt (Chống Nhảy Chữ)

### ⚠️ Triệu chứng & Nguyên nhân lỗi nhảy chữ trên MacBook T2
Khi gõ văn bản (tiếng Việt hoặc tiếng Anh), chữ có thể bị nhảy lung tung, mất ký tự, chèn sai vị trí hoặc con trỏ chuột tự nhảy đi chỗ khác:
* **Mặt Trackpad MacBook quá lớn:** Khi đặt tay gõ phím, lòng bàn tay / gò ngón cái tự nhiên tì hoặc quẹt lướt qua mặt trackpad.
* **Tính năng `tap-to-click`:** Nếu bật `tap-to-click` (chạm nhẹ mặt kính là click), mọi va chạm nhẹ từ lòng bàn tay đều bị nhận diện là một cú click chuột, khiến con trỏ soạn thảo nhảy sang vị trí con trỏ chuột đang đứng.
* **Xung đột dịch vụ `keyd` & `libinput`:** Máy sử dụng daemon `keyd` (gán Shift phải = Escape). `keyd` phát phím qua thiết bị ảo `keyd virtual keyboard`, khiến `libinput` coi bàn phím là thiết bị ngoại vi và **vô hiệu hóa tính năng tự khóa trackpad khi gõ phím** (*Disable-While-Typing*).
* **Driver T2:** Driver trackpad T2 trên Linux (`tbtpd`) dễ phát sinh cảnh báo `libinput error: Touch jump detected and discarded`.

### ✅ Giải pháp chuẩn bắt buộc: TẮT HOÀN TOÀN `tap-to-click`
Người dùng **không dùng `tap-to-click`**. Giải pháp triệt để là tắt tính năng chạm nhẹ để click, đồng thời vẫn cho phép trackpad hoạt động song song với chuột ngoài:

```bash
# 1. Tắt vĩnh viễn tính năng chạm nhẹ để click (bắt buộc)
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false

# 2. Cho phép trackpad hoạt động bình thường (song song chuột ngoài)
gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
```

> [!IMPORTANT]
> Sau khi cấu hình lệnh trên:
> - Trackpad vẫn rê chuột và bấm click vật lý (*force touch click - ấn lún bàn rê xuống*) hoàn toàn bình thường.
> - Khi gõ phím, lòng bàn tay tì hoặc quẹt qua mặt trackpad sẽ **100% không bị kích hoạt click**, chấm dứt triệt để lỗi nhảy chữ / nhảy con trỏ.
> - Bộ gõ tiếng Việt `ibus-bamboo` hoạt động ổn định và chính xác mà không bị xung đột với con trỏ chuột.

