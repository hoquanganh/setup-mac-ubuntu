# 💻 Hướng Dẫn Cấu Hình Theo Loại Phần Cứng (Hardware Guide)

Hệ thống được thiết kế theo dạng mô-đun (Modular), hỗ trợ nhiều dòng máy khác nhau khi làm Home Server.

---

## 1. MacBook Pro (Chip Apple T2 - 2018 đến 2020)
* **Đặc điểm:** Bàn phím, trackpad, audio và card Wi-Fi Broadcom nằm trên chip T2. Kernel Ubuntu tiêu chuẩn không có sẵn driver.
* **Tự động cấu hình:** Script `hardware/t2-mac/install_t2_drivers.sh` sẽ:
  1. Thêm repo `adityagarg8/t2-ubuntu-repo`.
  2. Cài kernel `linux-t2` và `apple-firmware-script`.
  3. Giải nén firmware Wi-Fi/Bluetooth trực tiếp từ Apple Recovery.
* **Lưu ý:** Sau khi cài máy mới lần đầu, cần `sudo reboot` để khởi động vào kernel T2 mới.

---

## 2. Laptop Thông Thường (Generic Laptop - Dell, ThinkPad, Asus...)
* **Đặc điểm:** Máy có pin và màn hình gập. Mặc định Ubuntu sẽ đi vào chế độ Sleep / Suspend khi gập màn hình (Lid Close).
* **Tự động cấu hình:** Script `hardware/laptop-power/configure_power.sh` sẽ:
  1. Sửa `/etc/systemd/logind.conf` (`HandleLidSwitch=ignore`).
  2. Disable/Mask các target `sleep.target`, `suspend.target`, `hibernate.target`.
  3. Giúp laptop hoạt động liên tục 24/7 kể cả khi gập màn hình.

---

## 3. Máy Tính Bàn (Desktop PC / Intel NUC / Mini PC / Cloud VPS)
* **Đặc điểm:** Không có màn hình gập hay chip mã hóa đặc thù.
* **Cấu hình:** Hệ thống chạy trực tiếp các module `core/` mà không cần cài thêm driver hay cấu hình pin.

---

## 🛠️ Chọn Profile Thủ Công Khi Chạy Script

```bash
# Chọn MacBook T2
sudo ./bin/setup.sh --hardware=t2-mac

# Chọn Laptop thường
sudo ./bin/setup.sh --hardware=laptop

# Chọn Desktop PC / Mini PC
sudo ./bin/setup.sh --hardware=generic-pc
```
