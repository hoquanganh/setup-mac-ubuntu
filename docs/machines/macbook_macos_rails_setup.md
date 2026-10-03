# 🍎 Machine Runbook: MacBook Pro — macOS Rails Development Setup

Tài liệu này hướng dẫn cài đặt lại chiếc **MacBook Pro** này (hoặc bất kỳ MacBook Apple Silicon M-series nào) với hệ điều hành **macOS** chuẩn, cấu hình môi trường lập trình **Ruby on Rails** hoàn chỉnh, và xử lý các lỗi thường gặp khi compile native gems.

---

## ⚡ 1-Click Cài Đặt Tự Động (macOS)

Sau khi cài đặt mới macOS (macOS Sequoia / Sonoma / Ventura):

1. Mở Terminal mặc định trên macOS.
2. Clone repo và chạy script:
   ```bash
   git clone https://github.com/hoquanganh/setup-mac-ubuntu.git ~/Documents/Ubuntu_install
   cd ~/Documents/Ubuntu_install
   ./bin/setup.sh --platform=macos --profile=dev-workstation
   ```

Script `setup_macos_rails.sh` sẽ tự động:
- Cài Xcode Command Line Tools.
- Cài đặt Homebrew và gói bundle `Brewfile`.
- Cấu hình biến môi trường trong `~/.zshrc` (rbenv, libpq, openssl flags).
- Khởi chạy nền PostgreSQL và Redis bằng `brew services`.
- Cài đặt Ruby 3.3.6 qua `rbenv` với cờ OpenSSL chuẩn.
- Cài đặt Bundler & Rails.

---

## 🛠️ Các Bước Cài Đặt Thủ Công (Chi Tiết)

### 1. Homebrew & Công Cụ Nền Tảng
```bash
# Cài đặt Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cài đặt các thư viện C cần thiết cho Rails
brew install openssl@3 readline libyaml gmp zlib vips libpq rbenv ruby-build git gh
```

### 2. Cài Đặt PostgreSQL & Redis
```bash
brew install postgresql@16 redis
brew services start postgresql@16
brew services start redis

# Tạo user postgres & rails
createuser -s postgres
createuser -s rails
```

### 3. Cài Đặt Ruby qua Rbenv
Để tránh lỗi `OpenSSL` khi build Ruby trên macOS:
```bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
echo 'export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline)"' >> ~/.zshrc

source ~/.zshrc

rbenv install 3.3.6
rbenv global 3.3.6
gem install bundler
```

---

## 🚨 Bảng Tra Cứu Lỗi Gem Rails Thường Gặp Trên macOS

Khi chạy `bundle install` các dự án Rails trên macOS, một số gem native C-extension có thể báo lỗi:

### 1. Gem `pg` (Không tìm thấy pg_config)
**Nguyên nhân:** Homebrew không link `libpq` vào `/usr/local/bin` hoặc `/opt/homebrew/bin` mặc định.  
**Khắc phục:**
```bash
bundle config --global build.pg --with-pg-config=$(brew --prefix libpq)/bin/pg_config
bundle install
```

### 2. Gem `nokogiri` (Lỗi libxml2 / libxslt)
**Khắc phục:**
```bash
bundle config --global build.nokogiri --use-system-libraries --with-xml2-include=$(brew --prefix libxml2)/include/libxml2
gem install nokogiri
```

### 3. Gem `vips` / `image_processing`
**Khắc phục:**
```bash
brew install vips
bundle install
```

### 4. Gem `mysql2` (Nếu dự án dùng MySQL)
**Khắc phục:**
```bash
brew install mysql-client openssl@3
bundle config --global build.mysql2 --with-opt-dir="$(brew --prefix openssl@3):$(brew --prefix zstd)" --with-mysql-config="$(brew --prefix mysql-client)/bin/mysql_config"
gem install mysql2
```

---

## 🏃 Chạy Dự Án Rails Trên macOS

```bash
cd ~/path/to/rails-project
bundle install
bin/rails db:prepare
bin/rails server
```
Website chạy tại: `http://localhost:3000`
