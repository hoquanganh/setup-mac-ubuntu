# 🖥️ Machine Runbook: Lenovo Desktop — Ubuntu 24.04 (Dev Workstation + VN-MDM)

Tài liệu này hướng dẫn từng bước thiết lập một máy bàn **Lenovo Desktop** (hoặc Generic PC) cài mới **Ubuntu 24.04 LTS** thành một máy trạm lập trình (Developer Workstation) và triển khai dự án **VN-MDM** (hỗ trợ cả 2 chế độ: **Docker** hoặc **Native Systemd**).

---

## ⚡ Thiết Lập 1-Click (Automated Setup)

Sau khi cài mới Ubuntu 24.04 trên máy Lenovo, mở Terminal và chạy:

```bash
git clone https://github.com/hoquanganh/setup-mac-ubuntu.git ~/Documents/Ubuntu_install
cd ~/Documents/Ubuntu_install

# Tùy chọn 1: Cài trọn gói Dev Workstation + VN-MDM qua Docker (Khuyên dùng cho máy dev)
sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=docker

# Tùy chọn 2: Cài trọn gói Dev Workstation + VN-MDM Native Systemd (Tương tự máy MacBook)
sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=native
```

---

## 📋 Chi Tiết Các Thành Phần Được Cài Đặt

### 1. Base Development & Tools
- `build-essential`, `curl`, `git`, `zsh`, `vim` (bản đầy đủ, không phải `vim.tiny`).
- Cấu hình Zsh làm shell mặc định: `chsh -s $(which zsh)`.

### 2. GUI Development Applications
- **Google Chrome:** Trình duyệt chuẩn cho web development.
- **Cursor IDE:** Trình soạn thảo AI cho code.
- **Warp Terminal:** Terminal hiện đại tích hợp AI.
- **TablePlus:** Cài đặt dạng AppImage tại `~/Documents/Systems/install-packs/` kèm desktop launcher trong menu ứng dụng.
- **Bộ gõ tiếng Việt:** Tự động cấu hình `ibus-bamboo` (hoặc `ibus-unikey`) cho Ubuntu 24.04.

### 3. Runtimes & Databases
- **Ruby:** Cài đặt thông qua `rbenv` + `ruby-build` (phiên bản 3.3.6 / 3.4.x).
- **Node.js:** Node.js v22.x LTS và npm.
- **Docker & Docker Compose:** Cài đặt Docker engine và cấp quyền cho user chạy không cần `sudo`.
- **Databases:** PostgreSQL 16+, Redis 7, MySQL 8.4, MongoDB 7.0.

### 4. Cloud & Kubernetes CLI
- **Azure CLI (`az`):** Tự động thêm repo Microsoft cho Ubuntu 24.04 (`noble`).
- **kubectl & kubelogin:** Quản lý cụm Kubernetes và đăng nhập Azure AKS.
- **Stern:** Xem log Kubernetes pod đa cụm.

---

## 🚀 Triển Khai Dự Án VN-MDM Trên Máy Lenovo

### Phương Án A: Sử Dụng Docker Compose (Nhanh, không xung đột gem/node)

```bash
cd ~/Documents/Ubuntu_install/apps/vn-mdm/docker
cp .env.example .env

# Khởi động toàn bộ stack
docker compose up -d

# Khởi tạo cơ sở dữ liệu
docker compose exec backend bundle exec rails db:prepare
```

Truy cập:
- Frontend: `http://localhost:3001`
- Backend API: `http://localhost:3000`

### Phương Án B: Triển Khai Native (Chạy trực tiếp trên OS qua Nginx)

```bash
sudo bash ~/Documents/Ubuntu_install/apps/vn-mdm/native/deploy_vnmdm.sh
```

Dịch vụ sẽ tự động kích hoạt trên cổng 80 qua Nginx và tự khởi động cùng máy tính.
