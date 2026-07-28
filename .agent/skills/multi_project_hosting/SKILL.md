---
name: Multi-Project Hosting & Service Routing
description: Deploying multiple applications (Rails, Next.js, Docker, Python, Go) on a single home server using Nginx VirtualHosts, reverse proxy routing, and systemd daemons. Read before hosting new apps.
---

# Agent Skill: Multi-Project Hosting & Service Routing

## Purpose
Instruct the AI Agent on how to onboard new web applications onto an existing home server without port conflicts or service degradation.

## Multi-App Routing Strategy
To host multiple applications (App A, App B, App C) on 1 machine:

### Option A: Subdomains via Nginx (Recommended)
- Host header `app1.home.domain` -> reverse proxy to `127.0.0.1:3000`
- Host header `app2.home.domain` -> reverse proxy to `127.0.0.1:8080`
- Host header `mdm.home.domain`  -> reverse proxy to `127.0.0.1:3001`

### Option B: Path-based Routing via Nginx
- `/` -> Frontend App (Port 3001)
- `/api` -> Backend API (Port 3000)
- `/dashboard` -> Analytics App (Port 4000)

## Workflow to Add a New Application
1. **Allocate Port**: Pick an unused internal port (e.g. 8080, 8081).
2. **Create Service Unit**: Place systemd unit file in `/etc/systemd/system/appname.service`.
3. **Configure Nginx**:
   - Copy `apps/templates/nginx-vhost-template.conf` to `/etc/nginx/sites-available/appname.conf`.
   - Symlink to `/etc/nginx/sites-enabled/`.
   - Test with `sudo nginx -t` and reload `sudo systemctl reload nginx`.
4. **Deploy Application**: Run application service `sudo systemctl enable --now appname`.
