# 🖥️ Lenovo Desktop & Generic PC Hardware Profile

Tài liệu và script cấu hình phần cứng tối ưu cho máy bàn **Lenovo ThinkCentre**, **IdeaCentre**, **Legion**, cũng như các dòng **Generic Desktop PC / NUC** chạy **Ubuntu 24.04 LTS**.

## 📌 Đặc điểm phần cứng
- CPU: Intel Core / AMD Ryzen đa nhân.
- RAM: 16GB - 64GB+.
- GPU: Intel UHD/Iris Graphics, AMD Radeon hoặc NVIDIA GeForce/RTX.
- Kết nối: Cổng Ethernet Gigabit (RJ45) có dây ổn định và card Wi-Fi/Bluetooth PCIe hoặc USB.

## ⚙️ Các tối ưu tự động (`configure_desktop.sh`)
1. **Chống tự động Sleep / Suspend:** Vô hiệu hóa chế độ sleep của Ubuntu để máy có thể chạy server hoặc dev nền tảng 24/7.
2. **Wake-on-LAN (WOL):** Cho phép bật máy từ xa qua mạng nội bộ bằng gói tin Magic Packet.
3. **Driver Đồ họa:** Kiểm tra tự động bằng `ubuntu-drivers` để đề xuất driver NVIDIA hoặc firmware AMD phù hợp.

## 🚀 Chạy thủ công
```bash
sudo bash hardware/desktop-lenovo/configure_desktop.sh
```
