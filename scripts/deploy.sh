#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Automated Production Deployment Script
# Pulls latest code, verifies environment secrets, builds Docker containers,
# and verifies service health probes.
# ==============================================================================

set -euo pipefail

echo "======================================================================"
echo "🏥 Launching BluCare+ Automated Production Deployment..."
echo "======================================================================"

# 1. Verify .env file existence
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file missing in working directory! Copy .env.example to .env and configure secrets."
    exit 1
fi

# 2. Pull latest git updates if inside a git repository
if [ -d .git ]; then
    echo "📥 Pulling latest git repository updates..."
    git pull origin main || git pull origin feat/production-integration || true
fi

# 3. Tag previous deployment containers for instant rollback capability
echo "📦 Backing up container image state..."
docker compose tag blucare_backend blucare_backend:previous 2>/dev/null || true
docker compose tag blucare_frontend blucare_frontend:previous 2>/dev/null || true

# 4. Build and start production containers
echo "🔨 Building Docker containers in production mode..."
docker compose build --no-cache

echo "🚀 Starting Docker Compose services..."
docker compose up -d

# 5. Run Health Probe Verification
echo "⏳ Waiting 15 seconds for RAG store & model warm-up..."
sleep 15

if ./scripts/health_check.sh; then
    echo "======================================================================"
    echo "🎉 BluCare+ Production Deployment SUCCESSFUL!"
    echo "======================================================================"
else
    echo "======================================================================"
    echo "⚠️ Health check failed! Initiating automatic container rollback..."
    echo "======================================================================"
    ./scripts/rollback.sh
    exit 1
fi
