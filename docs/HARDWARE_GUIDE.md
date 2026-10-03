# 💻 Hướng Dẫn Cấu Hình Theo Loại Phần Cứng (Hardware Guide)

Hệ thống được thiết kế theo dạng mô-đun (Modular), hỗ trợ nhiều dòng máy khác nhau khi làm Home Server hoặc Developer Workstation.

---

## 1. MacBook Pro (Chip Apple T2 - 2018 đến 2020)
* **Đặc điểm:** Bàn phím, trackpad, audio và card Wi-Fi Broadcom nằm trên chip T2. Kernel Ubuntu tiêu chuẩn không có sẵn driver.
* **Tự động cấu hình:** Script `hardware/t2-mac/install_t2_drivers.sh` sẽ:
  1. Thêm repo `adityagarg8/t2-ubuntu-repo`.
  2. Cài kernel `linux-t2` và `apple-firmware-script`.
  3. Giải nén firmware Wi-Fi/Bluetooth trực tiếp từ Apple Recovery.
* **Lưu ý:** Sau khi cài máy mới lần đầu, cần `sudo reboot` để khởi động vào kernel T2 mới.
* **Chi tiết:** Xem [Runbook MacBook Pro 2019](file://docs/machines/macbook_pro_2019_ubuntu_server.md).

---

## 2. Máy Tính Bàn (Lenovo ThinkCentre M910q / Desktop PC / Intel NUC)
* **Đặc điểm:** Thường có card mạng có dây Ethernet Gigabit, cấu hình CPU cao, RAM lớn.
* **Tự động cấu hình:** Script `hardware/desktop-lenovo-m910q/configure_desktop.sh` sẽ:
  1. Tắt chế độ Sleep/Suspend tự động để máy luôn sẵn sàng hoạt động.
  2. Cấu hình Wake-on-LAN (WOL) để bật nguồn từ xa qua mạng nội bộ.
  3. Kiểm tra và tối ưu driver card đồ họa.
* **Chi tiết & Khôi phục tự động:** Xem [Hardware M910q Profile](file://hardware/desktop-lenovo-m910q/README.md) và [Runbook Lenovo Desktop](file://docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md).

---

## 3. Laptop Thông Thường (Generic Laptop - Dell, ThinkPad, Asus...)
* **Đặc điểm:** Máy có pin và màn hình gập. Mặc định Ubuntu sẽ đi vào chế độ Sleep / Suspend khi gập màn hình (Lid Close).
* **Tự động cấu hình:** Script `hardware/laptop-power/configure_power.sh` sẽ:
  1. Sửa `/etc/systemd/logind.conf` (`HandleLidSwitch=ignore`).
  2. Disable/Mask các target `sleep.target`, `suspend.target`, `hibernate.target`.
  3. Giúp laptop hoạt động liên tục 24/7 kể cả khi gập màn hình.

---

## 🛠️ Chọn Profile Thủ Công Khi Chạy Script

```bash
# Chọn MacBook T2
sudo ./bin/setup.sh --hardware=t2-mac

# Chọn Lenovo ThinkCentre M910q (hoặc alias desktop-lenovo)
sudo ./bin/setup.sh --hardware=desktop-lenovo-m910q

# Chọn Laptop thường
sudo ./bin/setup.sh --hardware=laptop

# Chọn PC / NUC / VPS tiêu chuẩn
sudo ./bin/setup.sh --hardware=generic-pc
```
