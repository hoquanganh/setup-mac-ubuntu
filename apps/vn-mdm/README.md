# 📱 VN-MDM Deployment Suite

Thư mục này chứa toàn bộ cấu hình triển khai cho dự án **VN-MDM** (Apple MDM Server: Rails API + Solid Queue Worker + Next.js Web + Nginx + ngrok HTTPS tunnel).

## 📂 Các phương thức triển khai

| Phương thức | Thư mục | Khi nào sử dụng | Đặc điểm |
|---|---|---|---|
| **Native Systemd (Hiện tại)** | [`native/`](file://apps/vn-mdm/native/) | Chạy máy chủ cố định 24/7 (như MacBook Pro 2019 này) | Tốc độ tối đa, quản lý trực tiếp bằng `systemctl`, tích hợp Nginx port 80 & ngrok HTTPS tunnel |
| **Docker Compose** | [`docker/`](file://apps/vn-mdm/docker/) | Chạy trên máy desktop dev khác (như Lenovo Ubuntu 24.04), CI/CD, hoặc môi trường cô lập | Đóng gói 100% (PostgreSQL, Redis, Backend, Worker, Frontend), không phụ thuộc vào rbenv/node của máy host |

---

## ⚡ Triển khai Native (Systemd + Nginx)

Dùng cho máy chủ hiện tại hoặc bất kỳ máy Ubuntu nào muốn chạy trực tiếp hiệu năng cao:

```bash
sudo bash apps/vn-mdm/native/deploy_vnmdm.sh
```

Dịch vụ quản lý:
- `sudo systemctl status vnmdm-backend`
- `sudo systemctl status vnmdm-worker`
- `sudo systemctl status vnmdm-frontend`
- `sudo systemctl status nginx`
- `sudo systemctl status ngrok-vnmdm`

---

## ⚡ Triển khai bằng Docker Compose

Dùng khi muốn bật nhanh dự án mà không cần cài rbenv hay node vào máy host:

```bash
cd apps/vn-mdm/docker
cp .env.example .env
docker compose up -d
docker compose exec backend bundle exec rails db:prepare
```
