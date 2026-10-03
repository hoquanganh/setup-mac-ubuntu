# 🍏 macOS Development Environment Setup & Best Practices

Hướng dẫn cấu hình hệ điều hành macOS (Intel & Apple Silicon) phục vụ phát triển ứng dụng Full-Stack, Docker, cơ sở dữ liệu và quản lý tiến trình nền.

---

## 1. Quản Lý Tiến Trình Nền với Homebrew Services

Khác với Linux dùng `systemd` (`systemctl`), macOS sử dụng `launchd`. Homebrew cung cấp lệnh `brew services` bọc ngoài rất tiện lợi:

```bash
# Khởi động và cho phép chạy cùng máy tính:
brew services start postgresql@16
brew services start redis

# Xem trạng thái:
brew services list

# Khởi động lại khi cần:
brew services restart postgresql@16

# Dừng dịch vụ:
brew services stop redis
```

---

## 2. Docker trên macOS: OrbStack vs Docker Desktop

Trên macOS, Docker không chạy trực tiếp trên nhân Darwin mà cần máy ảo Linux siêu nhẹ:
- **[OrbStack](https://orbstack.dev/) (Khuyên dùng):** Cực kỳ nhẹ, tốn ít hơn 100MB RAM, khởi động chỉ mất 2 giây, hỗ trợ cả Linux machines và Docker containers.
- **Docker Desktop:** Bản chuẩn chính thức của Docker.

Cài đặt bằng Homebrew Cask:
```bash
brew install --cask orbstack
```

---

## 3. Quản Lý Phiên Bản Runtimes (rbenv, nvm)

### Ruby với rbenv
```bash
# Liệt kê phiên bản có thể cài
rbenv install -l

# Cài phiên bản cụ thể
rbenv install 3.3.6

# Chọn phiên bản mặc định
rbenv global 3.3.6
```

### Node.js với nvm (hoặc Homebrew)
```bash
brew install nvm
mkdir ~/.nvm
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc

source ~/.zshrc
nvm install 22
nvm use 22
```
