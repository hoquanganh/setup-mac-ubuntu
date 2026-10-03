# 🚀 Universal Multi-Platform & Multi-Machine Quickstart Guide

Kho tài liệu và mã nguồn tự động hóa cài đặt môi trường cho nhiều dòng máy, nền tảng hệ điều hành (Ubuntu Linux, macOS) và dự án web.

---

## 🧭 Chọn Kịch Bản / Máy Cần Cài Đặt

| Mục Tiêu | Loại Máy / Hệ Điều Hành | Lệnh 1-Click | Runbook Chi Tiết |
|---|---|---|---|
| **Khôi phục máy này (24/7 Server)** | Apple MacBook Pro 2019 (T2) / Ubuntu | `sudo ./bin/restore_current_machine.sh` | [Runbook MacBook 2019 Server](file://docs/machines/macbook_pro_2019_ubuntu_server.md) |
| **Máy bàn Dev + Chạy VN-MDM** | Lenovo ThinkCentre / PC / Ubuntu 24.04 | `sudo ./bin/setup.sh --hardware=desktop-lenovo --profile=dev-workstation --app=vn-mdm --app-mode=docker` | [Runbook Lenovo Desktop](file://docs/machines/lenovo_desktop_ubuntu_dev_vnmdm.md) |
| **Cài lại macOS để Dev Rails** | MacBook Pro / macOS (Intel / M1/M2/M3/M4) | `./bin/setup.sh --platform=macos --profile=dev-workstation` | [Runbook macOS Rails](file://docs/machines/macbook_macos_rails_setup.md) |
| **Laptop bất kỳ làm Server 24/7** | Laptop Dell, HP, ThinkPad, Asus / Ubuntu | `sudo ./bin/setup.sh --hardware=laptop --auto` | [Hardware Guide](file://hardware/laptop-power/README.md) |
| **Cloud VPS / NUC / Mini PC** | Generic x86_64 PC / Ubuntu | `sudo ./bin/setup.sh --hardware=generic-pc --auto` | [Server Setup](file://docs/server/multi_project_hosting.md) |

---

## 📂 Cấu Trúc Kho Lưu Trữ

```text
├── bin/                          # Các script thực thi chính (setup.sh, restore_current_machine.sh)
├── platforms/                    # Scripts cài đặt theo hệ điều hành (ubuntu, macos)
│   ├── ubuntu/                   # Base tools, runtimes, databases, services, desktop apps
│   └── macos/                    # Brewfile, setup_macos_rails.sh
├── hardware/                     # Tối ưu hóa theo dòng máy phần cứng (macbook-t2, desktop-lenovo, laptop-power)
├── apps/                         # Cấu hình triển khai ứng dụng (vn-mdm native & docker, templates)
├── docs/                         # Toàn bộ cẩm nang và tài liệu tra cứu
│   ├── machines/                 # Runbooks theo từng loại máy cụ thể
│   ├── platform-guides/          # Kiến thức chuyên sâu Ubuntu & macOS, sửa lỗi Rails gems
│   └── server/                   # Hướng dẫn Nginx multi-project, Remote access, Troubleshooting
└── AGENTS.md                     # Bản đồ kỹ năng và quy tắc thực thi dành cho AI Agent
```

---

## 🤖 Dành Cho AI Agent (Antigravity, Cursor, Claude Code)
AI Agent khi nhận prompt từ người dùng cần đọc file [`AGENTS.md`](file://AGENTS.md) để:
1. Tra cứu ma trận quyết định theo ngữ cảnh máy tính.
2. Nạp skill tương ứng trong `.agent/skills/`.
3. Tự động chạy đúng script hoặc tra cứu cách giải quyết vấn đề xuyên suốt các nền tảng.
