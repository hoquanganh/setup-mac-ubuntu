# 🔑 Hướng Dẫn Kết Nối Từ Xa (Remote Access Guide)

Tài liệu này chi tiết các phương thức kết nối tới Home Server từ mạng nội bộ (LAN) cũng như từ ngoài Internet (WAN/4G).

---

## 📊 Bảng So Sánh Các Công Cụ Kết Nối

| Công cụ | Phạm vi | Cách truy cập | Ưu điểm |
|---|---|---|---|
| **Avahi (mDNS)** | Cùng Wi-Fi nội bộ | `http://<hostname>.local`<br>`ssh qa@<hostname>.local` | Không lo thay đổi IP router |
| **Tailscale (VPN)** | Mọi nơi trên thế giới | `http://100.x.y.z`<br>`ssh qa@100.x.y.z` | Bảo mật tuyệt đối, mã hóa P2P, không cần mở port |
| **ngrok (Tunnel)** | Công khai Internet | `https://xxxx.ngrok-free.app` | Chia sẻ demo nhanh cho người khác không có Tailscale |
| **Cloudflare Tunnel** | Công khai Internet với Domain | `https://subdomain.yourdomain.com` | Có HTTPS tự động, bảo mật WAF Cloudflare |

---

## 1. Avahi mDNS (Kết nối cùng WiFi)
Mặc định dịch vụ `avahi-daemon` đã được kích hoạt.
* Web: `http://qa-MacBookPro15-2.local`
* SSH: `ssh qa@qa-MacBookPro15-2.local`

---

## 2. Tailscale VPN (Truy cập riêng tư an toàn)
Tailscale tạo một mạng VPN ảo cá nhân giữa các thiết bị của bạn.
1. Kích hoạt trên server:
   ```bash
   sudo tailscale up
   ```
2. Mở đường dẫn hiển thị trên màn hình và đăng nhập tài khoản Google/GitHub.
3. Tải app Tailscale trên điện thoại hoặc máy tính cá nhân, đăng nhập cùng tài khoản.
4. Bạn có thể SSH hoặc mở web qua IP `100.x.y.z` của server từ bất kỳ đâu (4G, Wi-Fi quán cafe...).

---

## 3. ngrok (Chia sẻ Link Demo công khai)
Khi bạn muốn người dùng ngoài Internet (hoặc đối tác) truy cập thử trang web mà họ không có Tailscale:
1. Thêm authtoken (lần đầu):
   ```bash
   ngrok config add-authtoken <YOUR_TOKEN>
   ```
2. Mở tunnel tới Nginx (Port 80):
   ```bash
   ngrok http 80
   ```
3. Gửi đường dẫn HTTPS (dạng `https://xxxx.ngrok-free.app`) cho người cần dùng.
