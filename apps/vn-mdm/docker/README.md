# 🐳 VN-MDM Docker Deployment

Hướng dẫn chạy toàn bộ hệ thống VN-MDM (PostgreSQL, Redis, Rails API, Worker, Next.js Web) bằng Docker Compose.

## 🚀 Khởi động nhanh (Quickstart)

```bash
cd apps/vn-mdm/docker

# 1. Tạo file cấu hình môi trường
cp .env.example .env

# 2. Khởi động toàn bộ container
docker compose up -d

# 3. Chạy migration cơ sở dữ liệu
docker compose exec backend bundle exec rails db:prepare

# 4. Kiểm tra trạng thái
docker compose ps
docker compose logs -f
```

## 🌐 Các cổng truy cập
- **Frontend Web UI:** `http://localhost:3001`
- **Backend Rails API:** `http://localhost:3000`
- **PostgreSQL:** `localhost:5432`
- **Redis:** `localhost:6379`
