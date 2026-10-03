# 🚀 Universal Multi-Platform Setup & Knowledge Base

Hệ thống tự động hóa cài đặt, cấu hình môi trường và tổng hợp tri thức kỹ thuật cho nhiều dòng máy tính và hệ điều hành: **Ubuntu Linux** (22.04 / 24.04 / 26.04), **macOS** (Intel & Apple Silicon), **Apple MacBook T2**, **Lenovo Desktops**, **Laptops** và **Cloud VPS**.

Được tối ưu cho cả **kỹ sư (Human Developers)** lẫn **AI Agents** (Antigravity, Cursor, Claude Code, Gemini CLI).

---

## ⚡ Các Kịch Bản Khởi Chạy Nhanh (Quickstart)

### 1. Khôi phục máy chủ hiện tại (MacBook Pro 2019 T2 chạy Ubuntu 24/7)
Khi cài lại mới Ubuntu trên chiếc máy này, chỉ cần chạy duy nhất 1 lệnh:
```bash
git clone https://github.com/hoquanganh/setup-mac-ubuntu.git ~/Documents/Ubuntu_install
cd ~/Documents/Ubuntu_install
sudo ./bin/restore_current_machine.sh
```
*Tự động 100%: Driver T2, Wi-Fi firmware, chống sleep gập nắp, PostgreSQL, Redis, Node, Ruby, Nginx reverse proxy, 4 dịch vụ VN-MDM systemd và ngrok sync.*

### 2. Cài máy bàn Lenovo Desktop mới (Ubuntu 24.04 Dev + VN-MDM)
```bash
# Chạy VN-MDM qua Docker Compose (Khuyên dùng):
sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=docker

# Hoặc chạy Native Systemd:
sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=native
```

### 3. Cài lại máy MacBook với hệ điều hành macOS để lập trình Rails
```bash
./bin/setup.sh --platform=macos --profile=dev-workstation
```
*Tự động cài Homebrew, Brewfile, Xcode tools, rbenv, PostgreSQL@16, Redis, OrbStack và xử lý cờ OpenSSL / libpq khi build native gems.*

---

## 📂 Cấu Trúc Thư Mục Repository

```text
├── bin/                              # Các entrypoint thực thi
│   ├── setup.sh                      # Master orchestrator đa nền tảng
│   └── restore_current_machine.sh    # Script 1-click khôi phục cho MacBook Pro 2019 Ubuntu
│
├── platforms/                        # Cấu hình theo hệ điều hành
│   ├── ubuntu/                       # Base tools, runtimes, databases, services, desktop apps
│   │   ├── base/                     # Build tools, zsh, vim
│   │   ├── desktop-apps/             # Chrome, Cursor, Warp, TablePlus AppImage, ibus-bamboo
│   │   ├── runtimes/                 # rbenv/Ruby, Node.js, Docker, kubectl, Azure CLI
│   │   ├── databases/                # PostgreSQL, Redis, MySQL, MongoDB
│   │   ├── services/                 # Nginx, UFW, Avahi (.local), SSH, Tailscale
│   │   └── setup_dev_machine.sh      # Script cài trọn gói máy dev Ubuntu
│   └── macos/                        # Môi trường macOS
│       ├── Brewfile                  # Homebrew bundle (CLI, databases, GUI casks)
│       └── setup_macos_rails.sh      # Script cài đặt môi trường Rails trên macOS
│
├── hardware/                         # Tối ưu hóa theo dòng máy phần cứng
│   ├── macbook-t2/                   # Kernel linux-t2, audio config, Apple Wi-Fi firmware
│   ├── desktop-lenovo/               # Lenovo ThinkCentre / Generic PC keepalive & optimizations
│   └── laptop-power/                 # Chống sleep khi gập màn hình (Lid close 24/7)
│
├── apps/                             # Cấu hình dự án web
│   ├── vn-mdm/                       # Hệ thống VN-MDM
│   │   ├── native/                   # Systemd services, Nginx config, deploy & ngrok sync
│   │   └── docker/                   # Docker Compose stack (API, Worker, Web, DB, Redis)
│   └── templates/                    # Mẫu thêm ứng dụng mới (Docker / Nginx vhost)
│
├── docs/                             # Cẩm nang hướng dẫn & tri thức kỹ thuật
│   ├── QUICKSTART.md                 # Hướng dẫn tổng quát
│   ├── machines/                     # Runbooks chi tiết theo từng máy:
│   │   ├── macbook_pro_2019_ubuntu_server.md # MacBook Pro 2019 Ubuntu 24/7 Server
│   │   ├── lenovo_desktop_ubuntu_dev_vnmdm.md # Lenovo Desktop Ubuntu 24.04 Dev + VN-MDM
│   │   └── macbook_macos_rails_setup.md       # MacBook macOS Rails Setup
│   ├── platform-guides/              # Cẩm nang chuyên sâu:
│   │   ├── ubuntu_dev_guide.md       # Cẩm nang Ubuntu Dev (Warp, Cursor, TablePlus, K8s, Azure)
│   │   ├── macos_dev_guide.md        # Cẩm nang macOS (OrbStack, Homebrew services)
│   │   └── rails_troubleshooting_cross_platform.md # Khắc phục lỗi build gem Ruby (Ubuntu vs macOS)
│   └── server/                       # Vận hành server:
│       ├── multi_project_hosting.md  # Host nhiều dự án trên 1 server bằng Nginx
│       ├── remote_access.md          # Tailscale, ngrok, Avahi mDNS
│       └── troubleshooting.md        # Xử lý sự cố thường gặp
│
├── .agent/skills/                    # AI Agent Skills (Antigravity / Cursor / Claude Code)
└── AGENTS.md                         # Ma trận quyết định & chỉ dẫn tự động hóa cho AI Agent
```

---

## 🤖 Dành Cho AI Agent

Khi giao việc cho AI Agent (Antigravity, Cursor, Claude Code, v.v.):
1. Agent đọc [`AGENTS.md`](file://AGENTS.md) để xác định ngữ cảnh máy và ma trận quyết định.
2. Agent tham khảo các skill trong `.agent/skills/` tương ứng với yêu cầu.
3. Agent có thể tham khảo chéo các giải pháp giữa các nền tảng (ví dụ: cách fix lỗi native gem từ Linux sang macOS hoặc ngược lại) từ thư mục `docs/platform-guides/`.
