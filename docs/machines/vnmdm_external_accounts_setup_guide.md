# 🌐 Hướng Dẫn Thiết Lập Tài Khoản Ngoại Vi Cho VN-MDM
## (Cloudflare Tunnel, Tên Miền, Apple APNs, ABM / ADE, VPP)

Tài liệu này tổng hợp toàn bộ các bước thiết lập tài khoản dịch vụ bên ngoài để hệ thống **VN-MDM** trên máy **Lenovo ThinkCentre M910q** có thể kết nối Internet và quản lý thiết bị thật (iPhone, iPad, Mac).

---

## 📑 Mục Lục
1. [Cloudflare Tunnel & Tên Miền Cố Định (Bắt buộc cho MDM Internet)](#1-cloudflare-tunnel--tên-miền-cố-định)
2. [Tùy Chọn Phụ: ngrok HTTPS Tunnel (Nhanh cho thử nghiệm)](#2-tùy-chọn-phụ-ngrok-https-tunnel)
3. [Apple APNs (Chứng chỉ Push Notification - Bắt buộc gửi lệnh tới máy)](#3-apple-apns-push-notification)
4. [Apple Business Manager / ADE (Zero-Touch Enrollment - Tùy chọn)](#4-apple-business-manager--ade)
5. [Apple VPP / Apps & Books (Phân phối ứng dụng App Store - Tùy chọn)](#5-apple-vpp--apps--books)

---

## 1. Cloudflare Tunnel & Tên Miền Cố Định

> [!IMPORTANT]
> **Tại sao cần HTTPS công khai cố định?**
> Thiết bị Apple từ chối cài profile MDM qua HTTP thường hoặc IP nội bộ. `CheckInURL` và `ServerURL` được gắn cứng vào thiết bị lúc Enroll. Nếu dùng domain đổi liên tục thì mỗi lần đổi URL bạn phải **Erase và Enroll lại thiết bị**. Cloudflare Tunnel cung cấp HTTPS miễn phí, bảo mật và cố định vĩnh viễn.

### Bước 1.1: Chuẩn bị tài khoản & Tên miền
1. Đăng ký tài khoản miễn phí tại [Cloudflare Dashboard](https://dash.cloudflare.com).
2. Thêm tên miền của bạn vào Cloudflare (ví dụ: `yourdomain.com`) và trỏ Nameserver theo hướng dẫn của Cloudflare.

### Bước 1.2: Cài đặt `cloudflared` trên máy M910q
```bash
# 1. Thêm repo Cloudflare chính thức
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

# 2. Cài đặt package
sudo apt update
sudo apt install -y cloudflared
```

### Bước 1.3: Đăng nhập và tạo Tunnel
```bash
# Đăng nhập (sẽ hiện một đường link mở trên trình duyệt để chọn tên miền)
cloudflared tunnel login

# Tạo tunnel mới (ví dụ tên: m910q-vnmdm)
cloudflared tunnel create m910q-vnmdm
# Lệnh trên sẽ in ra một UUID (Tunnel ID) và lưu credentials tại ~/.cloudflared/<UUID>.json
```

### Bước 1.4: Cấu hình File Routing
Tạo file cấu hình `/etc/cloudflared/config.yml` (hoặc `~/.cloudflared/config.yml`):
```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```
Nội dung file:
```yaml
tunnel: <TUNNEL_UUID_CỦA_BẠN>
credentials-file: /etc/cloudflared/<TUNNEL_UUID_CỦA_BẠN>.json

ingress:
  # Trỏ subdomain mdm tới Nginx port 80 của máy M910q
  - hostname: mdm.yourdomain.com
    service: http://localhost:80
  - service: http_status:404
```
Copy file json credentials vào `/etc/cloudflared/`:
```bash
sudo cp ~/.cloudflared/<TUNNEL_UUID_CỦA_BẠN>.json /etc/cloudflared/
```

### Bước 1.5: Trỏ DNS Subdomain vào Tunnel & Khởi chạy Service
```bash
# Tạo bản ghi CNAME tự động
cloudflared tunnel route dns m910q-vnmdm mdm.yourdomain.com

# Cài đặt cloudflared thành systemd service tự chạy 24/7
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

### Bước 1.6: Cập nhật biến môi trường `MDM_SERVER_URL` trên server
Sau khi có domain HTTPS (ví dụ: `https://mdm.yourdomain.com`), cập nhật vào systemd của VN-MDM:
```bash
sudo systemctl edit vnmdm-backend
# Thêm:
# [Service]
# Environment="MDM_SERVER_URL=https://mdm.yourdomain.com"

sudo systemctl edit vnmdm-worker
# Thêm:
# [Service]
# Environment="MDM_SERVER_URL=https://mdm.yourdomain.com"

sudo systemctl daemon-reload
sudo systemctl restart vnmdm-backend vnmdm-worker
```

---

## 2. Tùy Chọn Phụ: ngrok HTTPS Tunnel

Nếu bạn chưa có thẻ tín dụng hoặc chưa có tên miền riêng, bạn có thể dùng **ngrok**:

1. Đăng ký tài khoản tại [ngrok.com](https://ngrok.com).
2. Lấy Auth Token từ trang Dashboard.
3. Kích hoạt trên máy M910q:
   ```bash
   ngrok config add-authtoken <TOKEN_CỦA_BẠN>
   ```
4. Đăng ký 1 static domain miễn phí dạng `*.ngrok-free.app` trên dashboard ngrok.
5. Chạy tunnel qua script có sẵn của dự án:
   ```bash
   cd ~/vn-mdm
   ./scripts/ngrok.sh --domain=<TEN_MIEN_STATIC>.ngrok-free.app
   ```
6. Đồng bộ URL vào database:
   ```bash
   ./scripts/refresh-server-urls.sh
   ```

---

## 3. Apple APNs (Push Notification)

> [!NOTE]
> Khi Admin bấm lệnh "Khóa máy", "Xóa máy", "Cài app", VN-MDM không gọi trực tiếp tới iPhone/Mac (vì thiết bị nằm sau mạng 4G/Wi-Fi NAT). Thay vào đó, VN-MDM gửi một tín hiệu Push qua Apple APNs Gateway (`api.push.apple.com:443`). Apple sẽ đánh thức thiết bị và ra lệnh cho thiết bị kết nối về server VN-MDM để lấy payload.

### Các bước lấy Chứng chỉ APNs:
1. Vào trang quản trị VN-MDM: `http://quang-anh-910q.local/panel/demo/settings/apple/push` (hoặc qua domain HTTPS).
2. Nhấn **"Tải về Certificate Signing Request (CSR)"** do hệ thống tạo ra.
3. Mở trang [Apple Push Certificates Portal](https://identity.apple.com/pushcert/) bằng Apple ID của bạn hoặc công ty.
4. Bấm **"Create a Certificate"** -> Upload file CSR vừa tải ở bước 2.
5. Apple sẽ xuất cho bạn file certificate dạng `.pem` hoặc `.cer`.
6. Quay lại trang VN-MDM, upload file chứng chỉ nhận được từ Apple vào hệ thống.
7. Trạng thái sẽ chuyển thành `Active` với Push Topic dạng `com.apple.mgmt.External.xxxx`.

---

## 4. Apple Business Manager / ADE (Zero-Touch Enrollment)

> Áp dụng khi công ty mua thiết bị Apple chính hãng có mã số doanh nghiệp (Organization D-U-N-S) để bóc seal mở máy là tự động nhận cấu hình quản trị.

1. Vào VN-MDM: `/panel/:alias/settings/apple/dep`.
2. Tải về file Public Certificate `.pem`.
3. Đăng nhập [Apple Business Manager](https://business.apple.com) -> Preferences -> MDM Servers -> **Add MDM Server**.
4. Đặt tên server (ví dụ: `VN-MDM Server`) -> Upload public key `.pem` ở bước 2.
5. Nhấn **"Download Token"** để lấy file `*.p7m`.
6. Quay lại VN-MDM -> Upload file `*.p7m` token vào hệ thống.
7. Toàn bộ danh sách số Serial Number được gán trong ABM sẽ tự động đồng bộ về VN-MDM.

---

## 5. Apple VPP / Apps & Books (Phân phối ứng dụng App Store)

1. Đăng nhập [Apple Business Manager](https://business.apple.com) -> Preferences -> Payments and Billing -> Apps and Books -> Content Tokens.
2. Tải về Content Token của Location mong muốn (file `.vpptoken`).
3. Mở VN-MDM: `/panel/:alias/settings/apple/vpp`.
4. Upload file `.vpptoken`.
5. Hệ thống sẽ kết nối với Apple App Store và tải về danh mục các ứng dụng đã mua bản quyền để sẵn sàng cài đặt xuống thiết bị.
