# 🖥️ Lenovo ThinkCentre M910q Hardware Profile & Installed Inventory

Hồ sơ phần cứng, danh mục ứng dụng/môi trường đã cài đặt và kịch bản thiết lập tự động cho máy trạm kiêm server **Lenovo ThinkCentre M910q Tiny** chạy **Ubuntu 24.04 LTS (Noble Numbat)**.

---

## 📌 1. Thông số Phần cứng & Hệ điều hành (Live Snapshot)

| Thông số | Giá trị thực tế trên máy |
|---|---|
| **Dòng máy (Model)** | **Lenovo ThinkCentre M910q Tiny** (Form factor: Desktop Mini) |
| **Hostname** | `quang-anh-910q` (mDNS: `quang-anh-910q.local`) |
| **CPU** | Intel(R) Core(TM) i5-6500T CPU @ 2.50GHz (4 nhân, 4 luồng, Turbo 3.10GHz, TDP 35W) |
| **RAM** | 16 GB DDR4 (15 GiB thực tế, ~5.2 GiB available khi chạy GNOME GUI) |
| **Ổ cứng** | NVMe SSD 256 GB (`/dev/nvme0n1p2`, ~99 GB dung lượng trống khả dụng) |
| **GPU** | Intel HD Graphics 530 (tích hợp) |
| **Mạng (Network)** | - Wi-Fi (`wlp2s0`): `192.168.100.201/24`<br>- Ethernet (`enp0s31f6`): Intel I219-LM Gigabit (có hỗ trợ Wake-on-LAN) |
| **Hệ điều hành** | Ubuntu 24.04.1 LTS (Noble Numbat) |
| **Kernel** | Linux `6.17.0-14-generic` x86_64 |
| **User chính** | `quanganhho` (UID: `1000`, Sudoer, Home: `/home/quanganhho`) |

---

## 📦 2. Danh mục Môi trường & Dự án Đang Hoạt động

Máy này đang đóng vai trò vừa là **máy trạm phát triển (Dev Workstation)** vừa là **server nội bộ**. Khi thiết lập thêm dự án mới (như `vn-mdm`), **tuyệt đối không cài đè, không xóa cấu hình và không xung đột cổng (port conflict)**.

### 2.1. Cơ sở dữ liệu (Database Services)
| Service | Phiên bản | Port | Trạng thái | Ghi chú an toàn |
|---|---|---|---|---|
| **MySQL** | `mysql-server 8.0.45` | `3306` | Đang chạy (Active) | Giữ nguyên, không đổi cấu hình |
| **MongoDB** | `mongodb-org 6.0.27` | `27017` | Đang chạy (Active) | Giữ nguyên dữ liệu tại `/var/lib/mongodb` |
| **PostgreSQL** | *Chưa cài trên máy* | `5432` | Cần cài cho `vn-mdm` | Cài qua `apt` gốc, không xung đột MySQL/Mongo |
| **Redis** | *Chưa cài trên máy* | `6379` | Tuỳ chọn cho cache/solid queue | Cài qua `apt` gốc nếu cần |

### 2.2. Version Managers & Ngôn ngữ lập trình
Các version managers đã cấu hình trong `~/.zshrc` và `~/.bashrc`:
- **rbenv** (`~/.rbenv`):
  - Phiên bản hiện có: `2.7.6`, `3.1.0` (mặc định hiện tại), `3.1.2`, `3.2.1`, `3.3.0`, `3.3.5`, `3.4.4`, **`3.4.7`** (ĐÃ CÀI SẴN - đúng phiên bản `vn-mdm` yêu cầu!).
  - Shims: `/home/quanganhho/.rbenv/shims/ruby`, `bundle`, `gem`.
- **nodenv** (`~/.nodenv`):
  - Phiên bản hiện có: `16.19.1` (mặc định hiện tại), **`22.18.0`** (ĐÃ CÀI SẴN - Node 22 LTS tối ưu cho Next.js 15+!).
  - Shims: `/home/quanganhho/.nodenv/shims/node`, `npm`.
- **pyenv** (`~/.pyenv`): Đã cài cấu trúc thư mục, phiên bản hệ thống Python 3.12.
- **Java**: OpenJDK `21.0.10` (build 21.0.10+7-Ubuntu-124.04).

### 2.3. Các dự án đang có tại Home (`/home/quanganhho`)
1. `vn-mdm/`: Dự án mới clone về, chuẩn bị setup server.
2. `MDM/`: Chứa các subproject: `clomo`, `clomo-apply`, `clomo-manage-api`, `panel-front`, `securedapps-manager`.
3. `intheos/`: Chứa `dstp-lss-console`.
4. `dev/`:
   - `restaurant-order/`
   - `setup-mac-ubuntu/` (Kho lưu trữ tự động hóa này)
   - `test1/`

### 2.4. Ứng dụng Desktop & Công cụ CLI đã cài
- **Terminal & IDE**: Warp Terminal (`warp-terminal`), Cursor IDE (`/usr/bin/cursor`), VS Code (`code`), Sublime Text.
- **Trình duyệt**: Google Chrome (`google-chrome`), Firefox, Chromium.
- **Database GUI**: TablePlus (AppImage), MongoDB Compass (`mongodb-compass`), DBeaver CE, MySQL Workbench.
- **Cloud & K8s**: `kubectl`, `kubelogin`, Azure CLI (`~/.azure`), AWS CLI (`~/.aws`), OCI CLI (`~/oci-cli-env`).
- **Kho cài đặt cục bộ**: `/home/quanganhho/Documents/Systems/install-packs/` chứa sẵn các file cài (.deb, .AppImage, .zip):
  - `TablePlus-x64.AppImage` + icon
  - `Cursor-2.2.23-x86_64.AppImage`
  - `google-chrome-stable_current_amd64.deb`
  - `warp-terminal_...deb`
  - `mongodb-compass_1.46.0_amd64.deb`
  - `kubelogin-linux-amd64.zip`

---

## ⚖️ 3. Phân tích Kỹ thuật: Docker vs Chạy Trực Tiếp (Native) cho VN-MDM trên M910q

### So sánh chi tiết

| Tiêu chí | Docker / Docker Compose | Chạy trực tiếp (Native via Systemd) | Đánh giá trên M910q |
|---|---|---|---|
| **Tài nguyên RAM** | Tốn thêm ~1.5GB - 2.5GB (daemon Docker + container runtime + build cache) | Tốn ~500MB - 800MB (Puma Rails + Node Next.js + Postgres local) | **Native thắng vượt trội**: M910q còn ~5GB RAM khả dụng khi mở IDE & Chrome. Docker dễ dẫn tới tràn RAM / swap giật lag. |
| **Hiệu năng CPU** | Overhead mạng ảo (bridge) và ảo hóa filesystem (overlay2) trên CPU i5 4 nhân | Sử dụng trực tiếp nhân Linux kernel, tối đa xung nhịp 3.1GHz | **Native thắng**: i5-6500T (4 cores/4 threads) build assets & chạy Puma native nhanh hơn 30-40%. |
| **Thời gian chuẩn bị** | Phải kéo image Docker, cài Docker engine, compile lại gem trong container | **Ruby 3.4.7 & Node 22.18.0 đã có sẵn trong rbenv & nodenv**! Chỉ cần `bundle install` và `npm install`. | **Native thắng**: Tiết kiệm hàng giờ tải và build container. |
| **Giao thức Apple MDM & APNs** | Đẩy push APNs HTTP/2 qua mạng Docker bridge đôi khi bị timeout hoặc lỗi socket ALPN | Socket HTTP/2 raw trực tiếp ra internet tới `api.push.apple.com:443`, độ trễ cực thấp | **Native thắng**: Rất quan trọng cho tính ổn định của Apple Push Notification service. |
| **Tính tương thích Runbook VN-MDM** | `docker-compose.yml` trong repo vn-mdm chỉ là bản dev mẫu, chưa tích hợp Cloudflare Tunnel và APNs production | Toàn bộ tài liệu chính thức (`vn-mdm/docs/10-qa-server-deploy.md`, `scripts/deploy.sh`) được thiết kế riêng cho **Systemd native daemons** (`vnmdm-*`) | **Native thắng**: Đồng nhất 100% với runbook chuẩn của dự án vn-mdm. |
| **Quản lý tự khởi động & giám sát** | Docker restart policy (`restart: unless-stopped`) | Systemd unit (`Restart=always`, `journalctl`, quản lý phụ thuộc dịch vụ mạng) | **Tương đương**, Systemd chuẩn gốc của Ubuntu. |

> [!IMPORTANT]
> **KẾT LUẬN & KHUYẾN NGHỊ:**
> Đối với máy **Lenovo ThinkCentre M910q (i5-6500T, 16GB RAM, đang chạy nhiều dự án khác)**, phương án **CHẠY TRỰC TIẾP (NATIVE VIA SYSTEMD + NGINX)** là **tốt nhất, nhẹ nhất, ổn định nhất và chuẩn xác nhất** theo đúng tài liệu kiến trúc của `vn-mdm`.

---

## 🏛️ 4. Kiến trúc Hệ thống khi Chạy Trực Tiếp (Native Topology)

```mermaid
graph TD
    Device[Apple iOS / macOS / Android] -->|HTTPS :443| Cloudflare[Cloudflare Tunnel / ngrok]
    AdminBrowser[Trình duyệt Admin / Dev] -->|HTTP :80 hoặc HTTPS| Cloudflare
    
    subgraph Lenovo M910q [Lenovo ThinkCentre M910q - Ubuntu 24.04]
        Cloudflare -->|HTTP :80| Nginx[Nginx Reverse Proxy :80]
        
        Nginx -->|/ (Admin Web)| NextJS[Next.js Frontend :3001<br>Node 22.18.0 via systemd]
        Nginx -->|/api, /mdm, /enroll, /:alias/*| Rails[Rails API :3000<br>Ruby 3.4.7 Puma via systemd]
        
        Rails --> Worker[Solid Queue Worker bin/jobs<br>via systemd]
        Rails --> Postgres[(PostgreSQL :5432<br>vn_mdm_development/production)]
        Worker --> Postgres
        
        Worker -->|HTTP/2 ALPN :443| APNS[Apple APNs Push Gateway]
        Rails -->|Faraday TLS :443| ABM[Apple Business Manager ADE/VPP]
        
        subgraph Existing [Các dịch vụ đã có từ trước - Được bảo toàn]
            MySQL[(MySQL Server :3306)]
            Mongo[(MongoDB Server :27017)]
            Avahi[Avahi mDNS quang-anh-910q.local]
            WarpCursor[Warp / Cursor / TablePlus]
        end
    end
```

### Phân bổ Cổng (Port Mapping) Tuyệt đối Không Xung Đột
- `3306`: MySQL (Dự án cũ - Giữ nguyên)
- `27017`: MongoDB (Dự án cũ - Giữ nguyên)
- `5432`: PostgreSQL (Mới cài cho VN-MDM)
- `3000`: Rails API VN-MDM (Localhost)
- `3001`: Next.js UI VN-MDM (Localhost)
- `80`: Nginx Reverse Proxy tiếp nhận traffic nội bộ LAN và Tunnel
- `4040`: ngrok dashboard (nếu dùng ngrok) hoặc `cloudflared` metrics

---

## 🛠️ 5. Kịch bản Tự động hóa Idempotent (`setup_m910q_environment.sh`)

Nguyên tắc bắt buộc khi chạy cài đặt hoặc phục hồi máy này:
> **"Trước khi cài luôn kiểm tra máy đã có chưa nếu có rồi thì không cài lại mà sử dụng bản hiện có hoặc update nếu cần"**

Kịch bản `setup_m910q_environment.sh` được tích hợp sẵn các bước kiểm tra (pre-flight checks):
1. **Kiểm tra phần cứng & nguồn:** Bật chống sleep/suspend, cấu hình Wake-on-LAN cho cổng Ethernet.
2. **Kiểm tra rbenv & Ruby:** Kiểm tra xem `rbenv` và Ruby `3.4.7` có chưa. Nếu có rồi thì bỏ qua không compile lại.
3. **Kiểm tra nodenv & Node:** Kiểm tra xem `nodenv` và Node `22.18.0` có chưa. Nếu có rồi thì bỏ qua.
4. **Kiểm tra Cơ sở dữ liệu:**
   - MySQL & MongoDB: Kiểm tra nếu đã có thì giữ nguyên, đảm bảo service đang bật.
   - PostgreSQL: Nếu chưa có `psql` thì mới cài đặt `postgresql`, tạo database `vn_mdm_development` và user `vnmdm`.
5. **Kiểm tra Nginx & Reverse Proxy:** Nếu chưa có thì mới cài `nginx`, áp dụng cấu hình proxy cho `vn-mdm`.
6. **Kiểm tra Desktop Apps:** Tận dụng bộ cài offline tại `~/Documents/Systems/install-packs` nếu máy cần cài lại.

---

## 🚀 6. Hướng dẫn Chạy

```bash
# 1. Tối ưu hoá phần cứng M910q (chống sleep, bật WOL):
sudo bash hardware/desktop-lenovo-m910q/configure_desktop.sh

# 2. Chạy kịch bản kiểm tra và thiết lập môi trường idempotent:
sudo bash hardware/desktop-lenovo-m910q/setup_m910q_environment.sh
```
