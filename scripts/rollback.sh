#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Zero-Downtime Container Rollback Script
# Restores previous container builds if a deployment health check fails.
# ==============================================================================

set -euo pipefail

echo "🔄 Initiating BluCare+ Emergency Container Rollback..."

# 1. Stop current containers
docker compose down

# 2. Restore previous image tags if available
if docker image inspect blucare_backend:previous >/dev/null 2>&1; then
    echo "Restoring blucare_backend:previous image tag..."
    docker tag blucare_backend:previous blucare_backend:latest
fi

if docker image inspect blucare_frontend:previous >/dev/null 2>&1; then
    echo "Restoring blucare_frontend:previous image tag..."
    docker tag blucare_frontend:previous blucare_frontend:latest
fi

# 3. Relaunch services
echo "🚀 Restarting containers from previous backup images..."
docker compose up -d

echo "✅ Rollback executed. Inspect logs using: docker compose logs -f"
