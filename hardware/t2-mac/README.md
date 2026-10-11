# 🍎 Apple MacBook Pro T2 Chip (2018–2020) Hardware Profile

Hướng dẫn và script tự động cài đặt driver phần cứng cho các dòng MacBook có chip bảo mật Apple T2 chạy Ubuntu Linux (Ubuntu 22.04 / 24.04 / 26.04).

## 💻 Các model hỗ trợ
- MacBookPro15,1 / MacBookPro15,2 / MacBookPro15,3 / MacBookPro15,4 (13" & 15" 2018–2019)
- MacBookPro16,1 / MacBookPro16,2 / MacBookPro16,3 / MacBookPro16,4 (13" & 16" 2019–2020)
- MacBookAir8,1 / MacBookAir8,2 / MacBookAir9,1 (2018–2020)
- Macmini8,1 (2018)

## ⚠️ Vấn đề trên Kernel Linux mặc định
Kernel gốc của Ubuntu thiếu driver giao tiếp với chip T2, dẫn đến:
- Bàn phím tích hợp và Trackpad không nhận.
- Wi-Fi và Bluetooth không hoạt động (thiếu firmware độc quyền của Apple).
- Loa trong và Micro không có âm thanh.

## 🛠️ Giải pháp tự động hóa (`install_t2_drivers.sh`)
Script tự động:
1. Thêm kho PPA `t2-ubuntu-repo` (AdityaGarg8).
2. Cài đặt kernel `linux-t2`, cấu hình âm thanh `apple-t2-audio-config` và công cụ trích xuất firmware `apple-firmware-script`.
3. Tải và giải nén Apple Wi-Fi/Bluetooth firmware từ máy chủ Apple:
   ```bash
   sudo get-apple-firmware get_from_online
   ```
4. Sau khi reboot, toàn bộ bàn phím, trackpad, Wi-Fi, bluetooth và audio hoạt động bình thường!

## 🚀 Chạy script
```bash
sudo bash hardware/t2-mac/install_t2_drivers.sh
```
