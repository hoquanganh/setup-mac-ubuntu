---
name: VN-MDM Live Server Setup & Real Device Integration
description: Setting up, deploying, and verifying the VN-MDM platform on a live server with Nginx, Solid Queue worker, ngrok HTTPS tunnel, APNs push, and ABM/ADE zero-touch enrollment.
---

# VN-MDM Live Server Setup & Real Device Integration

## Purpose
Instruct AI Agents and System Administrators on how to deploy, configure, and maintain the `vn-mdm` platform on a live Ubuntu Home Server for real Apple device enrollment (iOS/macOS) via APNs, ADE (Automated Device Enrollment), ABM (Apple Business Manager), and ngrok HTTPS tunneling.

---

## 🏗️ Architecture & Component Layers

```mermaid
graph TD
    Device[Real Device iPhone / iPad / Mac] -->|HTTPS ngrok / Domain| Nginx[Nginx Reverse Proxy :80]
    
    subgraph Home Server
        Nginx -->|/api, /mdm, /enroll, /:alias/*| Rails[Rails API :3000]
        Nginx -->|/ (Web UI)| NextJS[Next.js Frontend :3001]
        
        Rails --> Worker[Solid Queue Worker bin/jobs]
        Rails --> Postgres[(PostgreSQL)]
        Rails --> Redis[(Redis)]
        
        Worker -->|APNs Push HTTP/2| AppleAPNS[Apple APNs Push Servers]
        Rails -->|Faraday TLS 1.2| AppleABM[Apple Business Manager ADE API]
    end
```

---

## ⚡ Deployment & Verification Protocol

### Step 1: Nginx Location Pattern for Multi-Tenant Devices
Ensure `/etc/nginx/sites-available/vnmdm` routes all backend endpoints (including multi-tenant `/:alias/enroll/ade`, `/:alias/mdm/checkin`, `/:alias/mdm/connect`, `/:alias/apps/*`, `/:alias/vpp/callback`) to Rails (`:3000`):

```nginx
location ~ ^/(api|up|mdm|enroll|[^/]+/(mdm|enroll|apps|vpp)) {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Step 2: Background Worker Service (`vnmdm-worker.service`)
Real device commands (`DeviceLock`, `EraseDevice`, `DeviceInformation`, `SecurityInfo`) rely on `PushCommandJob`. A background worker **MUST** be active via Systemd:

```ini
[Unit]
Description=VN-MDM Solid Queue Worker
After=network.target postgresql.service redis-server.service vnmdm-backend.service

[Service]
Type=simple
User=qa
WorkingDirectory=/home/qa/vn-mdm/api
Environment="RAILS_ENV=development"
Environment="PATH=/home/qa/.rbenv/shims:/home/qa/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/home/qa/.rbenv/shims/bundle exec bin/jobs
Restart=always

[Install]
WantedBy=multi-user.target
```

### Step 3: Ngrok HTTPS Tunnel & MDM Server URL Synchronization
1. Real Apple devices **refuse HTTP**; enrollment profiles and checkin URLs must use HTTPS.
2. Obtain current ngrok HTTPS URL:
   ```bash
   curl -sf http://127.0.0.1:4040/api/tunnels | python3 -c "import sys, json; s=sys.stdin.read().strip(); print(next((t['public_url'] for t in json.loads(s).get('tunnels', []) if t.get('proto')=='https'), '') if s else '')"
   ```
3. Update ADE configuration & profile URLs when ngrok changes:
   ```bash
   cd /home/qa/vn-mdm/api
   MDM_SERVER_URL=$(curl -sf http://127.0.0.1:4040/api/tunnels | python3 -c "import sys, json; s=sys.stdin.read().strip(); print(next((t['public_url'] for t in json.loads(s).get('tunnels', []) if t.get('proto')=='https'), '') if s else '')") IMPORT_TOKEN=1 FORCE_TOKEN=1 CUSTOMER_ALIAS=test1 bundle exec rails runner script/refresh_ade_config.rb
   ```

---

## 🔑 Certificate & Token Prerequisites Checklist

| Component | Required File / Settings | Location / Command | Verification |
|---|---|---|---|
| **Identity Certificate** | `mdm_identity.p12` | `api/vendor/local_config/identity/mdm_identity.p12` | Generated via `script/generate_mdm_identity_p12.sh` |
| **APNs Certificate** | `apns_cert_with_key.pem` | `api/vendor/local_config/apns/apns_cert_with_key.pem` | `openssl rsa -in apns_cert_with_key.pem -check` |
| **APNs Customer DB** | `ApplePushCertificate` DB record | `script/import_apns_from_env.rb` or UI `/panel/:alias/settings/apple/push` | Customer `test1` has `topic: com.apple.mgmt.External.xxx` |
| **ADE ABM Keypair** | Private key & Public PEM | `api/vendor/local_config/abm/test1-ade-private.key` | Restored via `script/refresh_ade_config.rb` |
| **ABM Server Token** | `.p7m` PKCS7 binary token | `api/vendor/local_config/abm/*.p7m` | Validated against Apple ADE API (`org_name`) |
| **VPP Token** | Location token `.vpptoken` | Uploaded in UI `/panel/:alias/settings/apple/vpp` | VPP catalog sync succeeds |

---

## 🛠️ Diagnostics & Log Verification

```bash
# 1. Verify all 4 systemd daemons active:
sudo systemctl status vnmdm-backend vnmdm-worker vnmdm-frontend nginx

# 2. Monitor real device checkin log:
tail -f /home/qa/vn-mdm/api/log/development.log | grep -E 'PUT /mdm/checkin|PUT /mdm/connect|PushCommandJob'

# 3. Test APNs Push manually for a device:
cd /home/qa/vn-mdm/api && bundle exec rails runner '
d = Device.last
puts "Testing APNs push to device #{d.id} (#{d.model})..."
Push::ApnsPushService.new(d).push!
'
```
