#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Host Nginx Reverse Proxy & Certbot Let's Encrypt SSL Installer
# Usage: ./scripts/nginx_ssl_setup.sh your-domain.com your-email@domain.com
# ==============================================================================

set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-}"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: $0 <DOMAIN> <EMAIL>"
    echo "Example: $0 blucare.example.com admin@example.com"
    exit 1
fi

echo "🔒 Setting up Nginx Reverse Proxy and Certbot SSL for $DOMAIN..."

# 1. Copy host Nginx configuration
sudo cp blucare.nginx.conf /etc/nginx/sites-available/blucare
sudo sed -i "s/server_name _;/server_name $DOMAIN;/g" /etc/nginx/sites-available/blucare

# 2. Enable site config and test Nginx syntax
sudo ln -sf /etc/nginx/sites-available/blucare /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default || true
sudo nginx -t
sudo systemctl reload nginx

# 3. Request Let's Encrypt SSL Certificate via Certbot
echo "📜 Obtaining Let's Encrypt SSL Certificate..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect

echo "🎉 HTTPS/SSL successfully enabled for https://$DOMAIN!"
