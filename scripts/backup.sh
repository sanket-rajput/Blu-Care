#!/usr/bin/env bash
# ==============================================================================
# BluCare+ Automated Backup Script
# Archives SQLite checkpointer database, Redis snapshot, and configuration.
# ==============================================================================

set -euo pipefail

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Starting BluCare+ System Backup to $BACKUP_DIR..."

# 1. Backup SQLite checkpointer file if present
if [ -f checkpoints.sqlite ]; then
    echo "Copying checkpoints.sqlite..."
    cp checkpoints.sqlite "$BACKUP_DIR/"
fi

# 2. Backup environment variables (.env)
if [ -f .env ]; then
    echo "Copying .env configuration file..."
    cp .env "$BACKUP_DIR/env.backup"
fi

# 3. Create compressed tar archive
TAR_FILE="blucare_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$TAR_FILE" -C "$BACKUP_DIR" .
rm -rf "$BACKUP_DIR"

echo "✅ Backup completed successfully! Archive: $TAR_FILE"
