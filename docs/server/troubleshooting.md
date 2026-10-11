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

---

## 4. Gõ Phím Bị Nhảy Chữ / Con Trỏ Chuột Tự Nhảy Vị Trí (MacBook T2)
* **Triệu chứng:** Khi đang gõ phím (tiếng Việt hoặc tiếng Anh), con trỏ soạn thảo bị giật sang vị trí khác, chữ bị chèn lung tung hoặc xóa đè ký tự cũ; đôi khi con trỏ chuột tự nhảy trên màn hình.
* **Nguyên nhân:**
  1. Mặt Trackpad MacBook lớn, khi gõ phím lòng bàn tay dễ quẹt vào bề mặt kính.
  2. Tính năng `tap-to-click` đang bật (`true`) biến mọi va chạm nhẹ của lòng bàn tay thành một cú click chuột ngẫu nhiên.
  3. Dịch vụ `keyd` (gán phím) tạo bàn phím ảo khiến `libinput` mất khả năng tự ngắt trackpad khi gõ (*Disable-While-Typing*).
* **Cách khắc phục triệt để (Không dùng tap-to-click):**
  1. Tắt tính năng chạm nhẹ để click:
     ```bash
     gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
     ```
  2. Đảm bảo trackpad vẫn hoạt động song song với chuột ngoài:
     ```bash
     gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
     ```
  *(Trackpad vẫn rê chuột và bấm click vật lý bằng cách ấn lún bàn rê xuống hoàn toàn bình thường, nhưng lòng bàn tay chạm nhẹ khi gõ sẽ 100% không bị click làm nhảy chữ).*

