---
name: Core Server Infrastructure & Database Services
description: Setup and verify core server daemons: Nginx Reverse Proxy, PostgreSQL, Redis, MySQL, MongoDB, Node.js, Ruby, Docker, and UFW Firewall. Read before making infrastructure changes.
---

# Agent Skill: Core Server Infrastructure & Database Services

## Purpose
Instruct the AI Agent on how to verify, configure, and maintain database engines, runtimes, firewall rules, and Nginx reverse proxy daemons.

## Architecture Specification
- **Nginx Reverse Proxy**: Standard entrypoint binding HTTP port 80. Routes traffic based on path rules or Host header domains to underlying services (`127.0.0.1:3000`, `127.0.0.1:3001`, `127.0.0.1:8080`, etc.).
- **PostgreSQL**: Listening on `127.0.0.1:5432` for relational persistence.
- **Redis**: Listening on `127.0.0.1:6379` for caching & ActionCable / Sidekiq background jobs.
- **Systemd Daemons**: Automatic restart policies enabled (`Restart=always`) with multi-user target integration.

## Agent Execution Checklist
1. **Run Base & DB Provisioning**:
   ```bash
   sudo bash core/01_base_system.sh
   sudo bash core/02_databases.sh
   sudo bash core/03_runtimes.sh
   sudo bash core/04_nginx_webserver.sh
   ```
2. **Health Verification Commands**:
   - PostgreSQL: `pg_isready`
   - Redis: `redis-cli ping`
   - Nginx syntax check: `sudo nginx -t`
   - Active listening ports: `ss -tulpn | grep -E "80|5432|6379"`
