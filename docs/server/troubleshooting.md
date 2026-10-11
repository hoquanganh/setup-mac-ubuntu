# 🛠️ Cẩm Nang Xử Lý Sự Cố Máy Chủ (Server Troubleshooting Guide)

Tài liệu này tổng hợp các phương pháp chẩn đoán và khắc phục lỗi **hạ tầng máy chủ dùng chung** (áp dụng cho mọi thiết bị: Mini PC, Desktop, Laptop, Cloud VPS làm server).

> [!NOTE]
> Nếu bạn gặp sự cố phần cứng đặc thù của từng dòng máy riêng biệt (như driver Apple T2, Touch Bar hỏng, Wake-on-LAN máy bàn), vui lòng tra cứu trực tiếp tại [Bản Đồ Sự Cố Theo Từng Dòng Máy](#-bản-đồ-sự-cố-theo-từng-dòng-máy) ở cuối tài liệu này.

---

## 1. Dịch Vụ Web & Reverse Proxy Nginx (Port 80 / 443)

### Triệu chứng 1: Báo lỗi "502 Bad Gateway" khi truy cập Web
* **Nguyên nhân:** Nginx đang chạy nhưng ứng dụng backend phía sau (Rails API :3000 hoặc Next.js :3001) chưa khởi động hoặc bị crash.
* **Cách khắc phục:**
  1. Kiểm tra tiến trình backend đang lắng nghe cổng:
     ```bash
     ss -tulpn | grep -E "3000|3001"
     ```
  2. Kiểm tra log của service backend:
     ```bash
     sudo journalctl -u vnmdm-backend -n 50 --no-pager
     sudo journalctl -u vnmdm-frontend -n 50 --no-pager
     ```
  3. Khởi động lại service nếu bị treo:
     ```bash
     sudo systemctl restart vnmdm-backend vnmdm-frontend
     ```

### Triệu chứng 2: Không truy cập được Web App qua Port 80 (Connection Refused)
* **Nguyên nhân:** Nginx chưa được khởi động hoặc cấu hình Nginx bị lỗi cú pháp.
* **Cách khắc phục:**
  1. Kiểm tra cú pháp cấu hình Nginx:
     ```bash
     sudo nginx -t
     ```
  2. Kiểm tra trạng thái service Nginx:
     ```bash
     sudo systemctl status nginx
     ```
  3. Khởi động lại Nginx:
     ```bash
     sudo systemctl restart nginx
     ```

---

## 2. Dịch Vụ Ứng Dụng Systemd Bị Crash hoặc Treo

### Cách kiểm tra toàn bộ dịch vụ của máy chủ:
```bash
sudo systemctl status nginx postgresql redis vnmdm-backend vnmdm-worker vnmdm-frontend ngrok-vnmdm
```

### Xem log thời gian thực (Real-time Logs):
```bash
# Xem log backend Rails
sudo journalctl -u vnmdm-backend -f

# Xem log worker xử lý tác vụ nền
sudo journalctl -u vnmdm-worker -f

# Xem log frontend Next.js
sudo journalctl -u vnmdm-frontend -f

# Xem log tunnel ngrok
sudo journalctl -u ngrok-vnmdm -f
```

---

## 3. Cơ Sở Dữ Liệu & Bộ Đệm (PostgreSQL & Redis)

### Triệu chứng: Ứng dụng báo lỗi "Connection refused" tới database
* **Nguyên nhân:** PostgreSQL (port 5432) hoặc Redis (port 6379) bị dừng hoặc hết dung lượng ổ đĩa.
* **Cách khắc phục:**
  1. Kiểm tra dung lượng ổ cứng còn trống:
     ```bash
     df -h /
     ```
  2. Kiểm tra trạng thái PostgreSQL và Redis:
     ```bash
     sudo systemctl status postgresql redis-server
     ```
  3. Kiểm tra khả năng kết nối trực tiếp:
     ```bash
     pg_isready -h localhost -p 5432
     redis-cli ping
     ```
  4. Khởi động lại nếu dịch vụ tắt:
     ```bash
     sudo systemctl restart postgresql redis-server
     ```

---

## 4. Mạng Nội Bộ, Remote Access & Tường Lửa (UFW)

### Triệu chứng 1: Không kết nối được SSH hoặc bị "Connection refused"
* **Nguyên nhân:** Dịch vụ OpenSSH chưa chạy hoặc UFW firewall đang chặn cổng 22.
* **Cách khắc phục:**
  1. Kiểm tra trạng thái OpenSSH:
     ```bash
     sudo systemctl status ssh
     ```
  2. Kiểm tra và mở cổng qua UFW:
     ```bash
     sudo ufw status
     sudo ufw allow 22/tcp
     sudo ufw reload
     ```

### Triệu chứng 2: Không tìm thấy tên miền cục bộ `.local` (Avahi mDNS)
* **Nguyên nhân:** `avahi-daemon` chưa chạy hoặc mạng Wi-Fi/Router cô lập multicast (AP Isolation).
* **Cách khắc phục:**
  1. Kiểm tra service Avahi:
     ```bash
     sudo systemctl restart avahi-daemon
     ```
  2. Kiểm tra IP cục bộ của máy:
     ```bash
     hostname -I
     ```

---

## 5. Laptop Làm Server 24/7 Bị Mất Mạng Khi Gập Màn Hình

* **Nguyên nhân:** Ubuntu tự động kích hoạt chế độ Sleep / Suspend khi gập nắp máy (Lid Close).
* **Cách khắc phục:**
  1. Chạy script cấu hình nguồn laptop:
     ```bash
     sudo bash hardware/laptop-power/configure_power.sh
     ```
  2. Kiểm tra cấu hình logind:
     ```bash
     grep -E "HandleLidSwitch" /etc/systemd/logind.conf
     ```
     *(Giá trị chuẩn phải là: `HandleLidSwitch=ignore` và `HandleLidSwitchExternalPower=ignore`)*.

---

## 🧭 Bản Đồ Sự Cố Theo Từng Dòng Máy

Nếu gặp sự cố đặc thù theo phần cứng riêng của từng máy, vui lòng tra cứu tài liệu chuyên biệt dưới đây:

| Dòng Máy | Loại Thiết Bị & Ngữ Cảnh | Sự Cố Thường Gặp | Tài Liệu Chi Tiết |
|---|---|---|---|
| **Apple MacBook Pro 2019 (T2)** | Laptop T2 làm 24/7 Ubuntu Server | • **Touch Bar hỏng** (dùng `keyd` đổi Shift phải thành Esc)<br>• **Gõ chữ bị nhảy** (tắt `tap-to-click` trên trackpad)<br>• Mất Wi-Fi/Bluetooth (trích xuất firmware Apple)<br>• Không nhận phím/chuột sau cài Ubuntu (cài kernel `linux-t2`) | [Runbook MacBook Pro 2019](file://docs/machines/macbook_pro_2019_ubuntu_server.md#lệnh-xử-lý-sự-cố-đặc-thù) |
| **Lenovo ThinkCentre M910q** | Máy bàn Mini PC làm Dev Workstation | • Cấu hình Wake-on-LAN bật nguồn từ xa<br>• Tối ưu card mạng Ethernet có dây<br>• Docker daemon & quyền user `docker` | [Runbook Lenovo Desktop](file://docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md) |
| **MacBook macOS (Rails)** | MacBook Intel/Apple Silicon chạy macOS | • Xung đột Homebrew services (Postgres, Redis)<br>• Lỗi biên dịch C native gem (`nokogiri`, `pg`, `libvips`)<br>• Cấp quyền camera/microphone cho test | [Runbook macOS Rails](file://docs/machines/macbook_macos_rails_setup.md)<br>[Rails Cross-Platform Guide](file://docs/platform-guides/rails_troubleshooting_cross_platform.md) |
