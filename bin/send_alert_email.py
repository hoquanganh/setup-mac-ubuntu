#!/usr/bin/env python3
"""
send_alert_email.py
Sends email notifications (alerts, health checks, backup status) using Gmail SMTP.
Uses Python standard library only (zero external pip dependencies).
Automatically sources SMTP credentials from /etc/vn-mdm-landing/app.env or environment variables.
"""

import argparse
import os
import sys
import socket
import ssl
import smtplib
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def load_env_file(filepath):
    """Parses a simple KEY=VALUE environment file."""
    env = {}
    if not os.path.isfile(filepath):
        return env
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                # Strip optional quotes
                v = v.strip().strip("'\"")
                env[k.strip()] = v
    except Exception as e:
        print(f"[WARN] Could not read env file {filepath}: {e}", file=sys.stderr)
    return env

def get_smtp_config():
    """Discovers SMTP settings from file or environment."""
    config = {
        'host': 'smtp.gmail.com',
        'port': 465,
        'user': '',
        'pass': '',
        'to': '',
        'from': ''
    }

    # 1. Try /etc/vn-mdm-landing/app.env
    env = load_env_file('/etc/vn-mdm-landing/app.env')
    if not env:
        # 2. Try /etc/system-backup/alert.env
        env = load_env_file('/etc/system-backup/alert.env')

    if env:
        config['host'] = env.get('SMTP_HOST', config['host'])
        config['port'] = int(env.get('SMTP_PORT', config['port']))
        config['user'] = env.get('SMTP_USER', '')
        config['pass'] = env.get('SMTP_PASS', '')
        config['to'] = env.get('ALERT_EMAIL_TO', env.get('LEAD_MAIL_TO', env.get('SMTP_USER', '')))
        config['from'] = env.get('ALERT_EMAIL_FROM', env.get('LEAD_MAIL_FROM', env.get('SMTP_USER', '')))

    # Environment variables override file
    if os.getenv('SMTP_HOST'):
        config['host'] = os.getenv('SMTP_HOST')
    if os.getenv('SMTP_PORT'):
        config['port'] = int(os.getenv('SMTP_PORT'))
    if os.getenv('SMTP_USER'):
        config['user'] = os.getenv('SMTP_USER')
    if os.getenv('SMTP_PASS'):
        config['pass'] = os.getenv('SMTP_PASS')
    if os.getenv('ALERT_EMAIL_TO'):
        config['to'] = os.getenv('ALERT_EMAIL_TO')
    if os.getenv('ALERT_EMAIL_FROM'):
        config['from'] = os.getenv('ALERT_EMAIL_FROM')

    if not config['from']:
        config['from'] = config['user']
    if not config['to']:
        config['to'] = config['user']

    return config

def get_system_summary():
    """Gathers brief system metrics for the alert footer."""
    hostname = socket.gethostname()
    try:
        load = os.getloadavg()
        load_str = f"{load[0]:.2f}, {load[1]:.2f}, {load[2]:.2f}"
    except Exception:
        load_str = "N/A"
    try:
        stat = os.statvfs('/')
        free_gb = (stat.f_bavail * stat.f_frsize) / (1024**3)
        total_gb = (stat.f_blocks * stat.f_frsize) / (1024**3)
        disk_str = f"{free_gb:.1f} GB free / {total_gb:.1f} GB total"
    except Exception:
        disk_str = "N/A"
    return {
        'hostname': hostname,
        'load': load_str,
        'disk': disk_str,
        'time': datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z")
    }

def send_alert(subject, message, status='INFO', recipient=None, verbose=False):
    config = get_smtp_config()
    to_email = recipient or config['to']

    if not config['user'] or not config['pass']:
        print("[ERROR] Missing SMTP credentials! Set in /etc/vn-mdm-landing/app.env or environment variables.", file=sys.stderr)
        return False

    if not to_email:
        print("[ERROR] Missing recipient email address.", file=sys.stderr)
        return False

    sys_info = get_system_summary()

    status_colors = {
        'SUCCESS': '#10b981', # Green
        'ERROR': '#ef4444',   # Red
        'WARNING': '#f59e0b', # Amber
        'INFO': '#3b82f6'     # Blue
    }
    badge_color = status_colors.get(status.upper(), '#3b82f6')

    full_subject = f"[{sys_info['hostname']}][{status.upper()}] {subject}"

    # Plain text version
    plain_body = f"""Status: {status.upper()}
Host: {sys_info['hostname']}
Time: {sys_info['time']}
Load: {sys_info['load']}
Disk: {sys_info['disk']}

--- Details ---
{message}
"""

    # HTML formatted version
    html_body = f"""<!DOCTYPE html>
<html>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #1f2937; margin: 0; padding: 20px; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e5e7eb;">
    <div style="background-color: {badge_color}; padding: 16px 24px; color: #ffffff;">
      <h2 style="margin: 0; font-size: 18px; font-weight: 600;">{status.upper()} - {subject}</h2>
      <p style="margin: 4px 0 0; font-size: 13px; opacity: 0.9;">Machine: {sys_info['hostname']} | {sys_info['time']}</p>
    </div>
    <div style="padding: 24px;">
      <div style="background: #f3f4f6; border-radius: 6px; padding: 14px; font-family: monospace; font-size: 13px; white-space: pre-wrap; word-break: break-all; margin-bottom: 20px; border-left: 4px solid {badge_color};">
{message}
      </div>
      <table style="width: 100%; border-collapse: collapse; font-size: 12px; color: #6b7280; border-top: 1px solid #e5e7eb; padding-top: 12px;">
        <tr>
          <td style="padding: 4px 0;"><strong>Hostname:</strong> {sys_info['hostname']}</td>
          <td style="padding: 4px 0;"><strong>System Load:</strong> {sys_info['load']}</td>
        </tr>
        <tr>
          <td style="padding: 4px 0;"><strong>Disk Storage:</strong> {sys_info['disk']}</td>
          <td style="padding: 4px 0;"><strong>Timestamp:</strong> {sys_info['time']}</td>
        </tr>
      </table>
    </div>
  </div>
</body>
</html>"""

    msg = MIMEMultipart('alternative')
    msg['Subject'] = full_subject
    msg['From'] = f"Server Alert <{config['from']}>"
    msg['To'] = to_email

    msg.attach(MIMEText(plain_body, 'plain', 'utf-8'))
    msg.attach(MIMEText(html_body, 'html', 'utf-8'))

    try:
        context = ssl.create_default_context()
        if config['port'] == 465:
            server = smtplib.SMTP_SSL(config['host'], config['port'], context=context, timeout=20)
        else:
            server = smtplib.SMTP(config['host'], config['port'], timeout=20)
            server.starttls(context=context)

        with server:
            server.login(config['user'], config['pass'])
            server.sendmail(config['from'], [to_email], msg.as_string())
        if verbose:
            print(f"[OK] Email successfully sent to {to_email}")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to send email alert: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description="Send alert emails via Gmail SMTP")
    parser.add_argument("--subject", "-s", default="System Notification", help="Alert subject")
    parser.add_argument("--message", "-m", help="Alert message body (or read from stdin)")
    parser.add_argument("--status", choices=["SUCCESS", "ERROR", "WARNING", "INFO"], default="INFO", help="Alert status level")
    parser.add_argument("--to", help="Recipient email address (defaults to configured owner)")
    parser.add_argument("--test", action="store_true", help="Send a test notification")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    if args.test:
        success = send_alert(
            subject="Test Notification",
            message="This is a test notification from the Lenovo ThinkCentre M910q monitoring service.\nGmail SMTP authentication is working properly.",
            status="SUCCESS",
            recipient=args.to,
            verbose=True
        )
        sys.exit(0 if success else 1)

    message = args.message
    if not message:
        if not sys.stdin.isatty():
            message = sys.stdin.read().strip()
        else:
            message = "No message body provided."

    success = send_alert(
        subject=args.subject,
        message=message,
        status=args.status,
        recipient=args.to,
        verbose=args.verbose
    )
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
