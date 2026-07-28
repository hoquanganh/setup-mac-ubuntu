# 🛠️ Xử Lý Lỗi Thường Gặp (Troubleshooting Guide)

---

## 1. Lỗi Wi-Fi / Bàn Phím / Touchpad không hoạt động trên MacBook T2
* **Nguyên nhân:** Chưa cài kernel `linux-t2` hoặc chưa giải nén firmware Apple.
* **Cách khắc phục:**
  1. Kết nối mạng qua USB Tethering điện thoại hoặc USB Wi-Fi dongle.
  2. Chạy lệnh: `sudo bash hardware/t2-mac/install_t2_drivers.sh`
  3. Khởi động lại máy: `sudo reboot`

---

## 2. Server bị ngắt kết nối khi gập màn hình Laptop
* **Nguyên nhân:** Dịch vụ `systemd-logind` chưa được cấu hình bỏ qua `HandleLidSwitch`.
* **Cách khắc phục:**
  1. Chạy lại script cấu hình nguồn: `sudo bash hardware/laptop-power/configure_power.sh`
  2. Kiểm tra logind service: `sudo systemctl status systemd-logind`

---

## 3. Không truy cập được Web App qua Port 80
* **Kiểm tra trạng thái Nginx & Services:**
  ```bash
  sudo systemctl status nginx
  sudo systemctl status vnmdm-backend
  sudo systemctl status vnmdm-frontend
  ```
* **Xem nhật ký lỗi (Logs):**
  ```bash
  sudo journalctl -u nginx -f
  sudo journalctl -u vnmdm-backend -f
  sudo journalctl -u vnmdm-frontend -f
  ```
* **Kiểm tra cổng đang lắng nghe:**
  ```bash
  ss -tulpn | grep -E "80|3000|3001"
  ```
