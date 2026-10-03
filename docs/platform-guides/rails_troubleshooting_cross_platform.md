# 💎 Cross-Platform Rails Gem Troubleshooting (Ubuntu vs macOS)

Bảng tổng hợp xử lý các lỗi build C-extension của gem Ruby thường gặp khi di chuyển dự án Rails giữa **Ubuntu Linux** và **macOS** (Intel T2 hoặc Apple Silicon M1/M2/M3/M4).

---

## 1. So Sánh Giải Pháp Cài Đặt Thư Viện Biên Dịch

| Gem | Lỗi Phổ Biến | Khắc phục trên Ubuntu Linux | Khắc phục trên macOS (Homebrew) |
|---|---|---|---|
| **`nokogiri`** | `mkmf.rb can't find libxml2 / libxslt` | `sudo apt install -y libxml2-dev libxslt1-dev` | `brew install libxml2 libxslt`<br>`bundle config build.nokogiri --use-system-libraries` |
| **`pg`** | `Can't find the 'libpq-fe.h' header` hoặc `pg_config not found` | `sudo apt install -y libpq-dev postgresql-client` | `brew install libpq`<br>`bundle config build.pg --with-pg-config=$(brew --prefix libpq)/bin/pg_config` |
| **`mysql2`** | `Cannot allocate memory` hoặc thiếu `mysql.h` | `sudo apt install -y default-libmysqlclient-dev` | `brew install mysql-client openssl@3`<br>`bundle config build.mysql2 --with-opt-dir="$(brew --prefix openssl@3)" --with-mysql-config="$(brew --prefix mysql-client)/bin/mysql_config"` |
| **`vips` / `image_processing`** | `LoadError: Could not open library 'libvips'` | `sudo apt install -y libvips libvips-dev imagemagick` | `brew install vips imagemagick` |
| **`sqlite3`** | `sqlite3.h is missing` | `sudo apt install -y sqlite3 libsqlite3-dev` | `brew install sqlite3`<br>`bundle config build.sqlite3 --with-sqlite3-dir=$(brew --prefix sqlite3)` |
| **`ffi`** | `ffi_c.so: undefined symbol` | `sudo apt install -y libffi-dev` | `brew install libffi`<br>`bundle config build.ffi --enable-system-libffi` |
| **`psych`** | Thiếu YAML parser | `sudo apt install -y libyaml-dev` | `brew install libyaml` |

---

## 2. Biên Dịch Ruby Cũ (Ruby <= 3.0) trên macOS hoặc Ubuntu Mới

Khi dự án yêu cầu Ruby phiên bản cũ (ví dụ 2.7.x) nhưng hệ điều hành sử dụng OpenSSL 3:

### Trên Ubuntu 24.04:
```bash
# Cài đặt OpenSSL 1.1 legacy
sudo apt install -y libssl-dev
RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr" rbenv install 2.7.8
```

### Trên macOS:
```bash
brew install openssl@1.1 readline
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1) --with-readline-dir=$(brew --prefix readline)" rbenv install 2.7.8
```

---

## 3. Kiến Trúc Apple Silicon (arm64) vs Intel x86_64

Nếu gem chỉ cung cấp binary x86_64 trên macOS Apple Silicon:
```bash
# Chạy terminal hoặc bundle dưới chế độ Rosetta 2:
arch -x86_64 bundle install
```
Ngược lại, trên Ubuntu x86_64 (như chiếc MacBook Pro 2019 này hoặc PC Lenovo), toàn bộ gem đều biên dịch native x86_64 với hiệu năng cao nhất.
