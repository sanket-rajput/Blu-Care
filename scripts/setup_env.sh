#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Ubuntu 24.04 LTS Server Initialization & Environment Setup
# Installs Docker, Docker Compose v2, Nginx, Certbot, and configures UFW firewall.
# ==============================================================================

set -euo pipefail

echo "🚀 Starting BluCare+ Ubuntu 24.04 LTS Server Setup..."

# 1. Update Ubuntu repositories and install essential packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx

# 2. Install official Docker Engine & Docker Compose Plugin
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# 3. Configure Docker permissions
sudo usermod -aG docker "$USER" || true
sudo systemctl enable docker
sudo systemctl start docker

# 4. Configure UFW Firewall (Allow SSH, HTTP, HTTPS)
echo "🔒 Configuring UFW Firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable

echo "✅ Ubuntu 24.04 LTS server setup complete! Restart or run 'newgrp docker' to apply group permissions."
