# 🐧 Ubuntu Full-Stack Development Guide & Knowledge Base

Tài liệu này tổng hợp toàn bộ hướng dẫn, kinh nghiệm cài đặt các công cụ lập trình, cơ sở dữ liệu, cloud CLI và xử lý lỗi thực tế trên **Ubuntu 24.04 / 26.04 LTS**.

---

## 1. Công Cụ Lập Trình Cơ Bản

### Vim (Full package)
Ubuntu mặc định cài `vim-tiny` (thiếu syntax highlighting, thao tác chuột):
```bash
sudo apt update
sudo apt install -y vim
which vim   # Phải là /usr/bin/vim, không phải vim.tiny
```

### Zsh & Oh My Zsh
```bash
sudo apt install -y zsh
chsh -s $(which zsh)
echo $SHELL
```

### Bộ Gõ Tiếng Việt
**Cách 1: IBus Bamboo (Khuyên dùng cho Ubuntu mới)**
```bash
sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo
sudo apt update
sudo apt install -y ibus ibus-bamboo
ibus restart
# Vào Settings > Keyboard > Add Input Source > Vietnamese (Bamboo)
```

**Cách 2: Language pack tiếng Việt cơ bản**
```bash
sudo apt-get install -y language-pack-vi
# Log off > Settings > Keyboard > Add language
```

---

## 2. Ứng Dụng GUI Development

### Google Chrome
```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
```

### Warp Terminal & Cursor IDE
- **Warp:** Tải từ [warp.dev](https://www.warp.dev/) hoặc dùng apt repository:
  ```bash
  curl -fsSL https://releases.warp.dev/linux/keys/warp.asc | gpg --dearmor -o /etc/apt/keyrings/warpdotdev.gpg --yes
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/warpdotdev.gpg] https://releases.warp.dev/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/warpdotdev.list
  sudo apt update && sudo apt install -y warp-terminal
  ```
- **Cursor:** Tải từ [cursor.com/download](https://cursor.com/download)

### TablePlus (AppImage Launcher)
Do TablePlus chưa có gói apt chính thức cho Ubuntu 24.04/26.04 x86_64:
```bash
mkdir -p ~/Documents/Systems/install-packs
cd ~/Documents/Systems/install-packs
curl -fsSL "https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage" -o TablePlus-x64.AppImage
curl -fsSL "https://tableplus.com/resources/favicons/apple-icon-60x60.png" -o tableplus-icon.png
chmod +x TablePlus-x64.AppImage

# Tạo shortcut menu ứng dụng:
cat <<EOF > ~/.local/share/applications/tableplus.desktop
[Desktop Entry]
Name=TablePlus
Exec=/home/$USER/Documents/Systems/install-packs/TablePlus-x64.AppImage
Icon=/home/$USER/Documents/Systems/install-packs/tableplus-icon.png
Type=Application
Categories=Development;
Terminal=false
EOF
chmod +x ~/.local/share/applications/tableplus.desktop
update-desktop-database ~/.local/share/applications/
```

---

## 3. Runtimes: Ruby (Rbenv) & Node.js

### Thư Viện Biên Dịch Nền Tảng (Base Dependencies)
```bash
sudo apt install -y \
  git curl wget build-essential autoconf bison rustc libssl-dev \
  libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
  libreadline-dev libncurses5-dev libncursesw5-dev \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common pkg-config \
  imagemagick libvips \
  sqlite3 libsqlite3-dev \
  postgresql postgresql-contrib libpq-dev \
  redis-server unzip xz-utils tk-dev
```

### Rbenv & Ruby
```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

echo 'export RBENV_ROOT="$HOME/.rbenv"' >> ~/.zshrc
echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

source ~/.zshrc
rbenv install 3.3.6
rbenv global 3.3.6
gem install bundler
```

### Node.js (v22.x LTS)
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

---

## 4. Cơ Sở Dữ Liệu (Databases)

### PostgreSQL
```bash
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Tạo user rails
sudo -u postgres createuser -s -d -r rails || true
sudo -u postgres psql -c "ALTER USER rails WITH PASSWORD 'password';"
```

### MySQL 8.4
```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

# Tạo user dev
sudo mysql -e "CREATE USER IF NOT EXISTS 'rails'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost'; FLUSH PRIVILEGES;"
```

### MongoDB (MongoDB 7.0 trên Ubuntu 24.04+)
Nếu server repo MongoDB chưa có release chính thức cho Ubuntu mới (`noble`/`resolute`), sử dụng repo `jammy`:
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes

echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl enable --now mongod
```

---

## 5. Cloud, Kubernetes & DevOps Tools

### Azure CLI
```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update && sudo apt-get install -y azure-cli

# Đăng nhập với tài khoản doanh nghiệp:
# az login -> Sign-in Options -> Sign in to an Organization -> nhập domain
```

### kubelogin & kubectl
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/

# kubelogin
wget https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
unzip -q kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
rm -rf kubelogin-linux-amd64.zip bin

# Tải cấu hình AKS và convert sang Azure CLI login:
az aks get-credentials -g <RESOURCE_GROUP> -n <CLUSTER_NAME>
kubelogin convert-kubeconfig -l azurecli
```

### Stern (Kubernetes Log Streaming)
```bash
# Cài đặt qua Krew plugin manager
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="amd64" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${OS}_${ARCH}.tar.gz" &&
  tar zxvf "krew-${OS}_${ARCH}.tar.gz" &&
  ./"krew-${OS}_${ARCH}" install krew
)

echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
kubectl krew install stern

# Xem log:
kubectl stern '<pod-prefix>-*' -n <namespace> -c <container> --max-log-requests 200
```
