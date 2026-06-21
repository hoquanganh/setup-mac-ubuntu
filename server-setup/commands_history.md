# Commands History & Status

This file tracks the setup progress to ensure continuity across sessions.

## Phase 1: SSH Server Setup ✅
*   `sudo apt update && sudo apt install -y openssh-server` - **Status: DONE**
*   `sudo systemctl enable ssh && sudo systemctl start ssh` - **Status: DONE**
*   `sudo ufw allow OpenSSH` - **Status: DONE**

## Phase 2: Power Management ✅
*   Configured `/etc/systemd/logind.conf` to ignore lid switch (`HandleLidSwitch=ignore`). - **Status: DONE**
*   Masked sleep/suspend targets. - **Status: DONE**

## Phase 3: mDNS/Avahi ✅
*   `avahi-daemon` is installed and running (`qa-MacBookPro15-2.local`). - **Status: DONE**

## Phase 4 & 5: Core Services (Nginx, PostgreSQL, Redis, Dependencies) ✅
*   Created and ran `install_server.sh` which executed:
    *   `apt install -y nginx postgresql redis-server build-essential` etc. - **Status: DONE**
    *   Configured UFW for ports 80, 443, 3000, 3001. - **Status: DONE**

## Phase 6: Application Setup (~/vn-mdm) ✅
*   `pkexec bash -c 'sudo -u postgres psql -c "CREATE USER vnmdm WITH PASSWORD '\''vnmdm'\'';" || true; sudo -u postgres psql -c "ALTER USER vnmdm CREATEDB;"'` - **Status: DONE**
*   `cd ~/vn-mdm/api && rbenv local 3.4.7 && gem install bundler && bundle install && rails db:prepare` - **Status: DONE**
*   `cd ~/vn-mdm/web && npm install` - **Status: DONE**
*   Started Backend & Frontend manually initially - **Status: DONE**

## Phase 7: Systemd & Nginx (24/7 Setup) ✅
*   Created `/etc/systemd/system/vnmdm-backend.service` (Rails API on port 3000) - **Status: DONE**
*   Created `/etc/systemd/system/vnmdm-frontend.service` (Next.js on port 3001) - **Status: DONE**
*   Configured Nginx Reverse Proxy (`/etc/nginx/sites-available/vnmdm`):
    *   `location ~ ^/(api|mdm|enroll|up)` -> `http://127.0.0.1:3000`
    *   `location /` -> `http://127.0.0.1:3001`
*   `systemctl daemon-reload && systemctl enable --now vnmdm-backend vnmdm-frontend nginx` - **Status: DONE**
*   `systemctl restart nginx` - **Status: DONE**

System is successfully running and proxying requests.
