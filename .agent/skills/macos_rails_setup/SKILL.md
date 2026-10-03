---
name: macOS Rails & Web Development Setup
description: Setting up macOS (Apple Silicon or Intel MacBooks) with Homebrew, Xcode tools, rbenv/Ruby, PostgreSQL, Redis, OrbStack/Docker, and resolving cross-platform native gem compilation errors.
---

# macOS Rails & Web Development Setup Skill

This skill guides the AI Agent when a user wants to set up macOS for Ruby on Rails development or troubleshooting native gem compile issues on Apple platforms.

## 🎯 When to Use This Skill
- The user is running macOS (`Darwin`) or planning to install macOS on an Intel MacBook Pro or Apple Silicon Mac.
- The user asks how to set up Ruby, Rails, Bundler, PostgreSQL, Redis, or Docker on macOS.
- The user encounters gem compilation errors like `nokogiri`, `pg`, `libvips`, or `mysql2` on macOS.
- Reference machine runbook: [`docs/machines/macbook_macos_rails_setup.md`](file:///home/qa/Documents/Ubuntu_install/docs/machines/macbook_macos_rails_setup.md).
- Reference troubleshooting guide: [`docs/platform-guides/rails_troubleshooting_cross_platform.md`](file:///home/qa/Documents/Ubuntu_install/docs/platform-guides/rails_troubleshooting_cross_platform.md).

## 🚀 Execution Commands

To execute the automated setup script on macOS:
```bash
./bin/setup.sh --platform=macos --profile=dev-workstation
```
Or directly:
```bash
bash platforms/macos/setup_macos_rails.sh
```

## 🛠️ Common macOS Rails Gem Fixes
- **pg gem**:
  ```bash
  bundle config --global build.pg --with-pg-config=$(brew --prefix libpq)/bin/pg_config
  ```
- **Ruby compilation flags (OpenSSL & Readline)**:
  ```bash
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline)"
  ```
- **nokogiri**:
  ```bash
  bundle config --global build.nokogiri --use-system-libraries
  ```
