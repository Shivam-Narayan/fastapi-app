#!/usr/bin/env bash
set -euo pipefail

# Backup PostgreSQL database from docker compose. Adjust DB credentials if needed.
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BACKUP_DIR="$ROOT_DIR/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="fastapi_db_backup_$TIMESTAMP.sql"
TARGET="$BACKUP_DIR/$FILENAME"

echo "Creating backup file: $TARGET"

docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
  pg_dump -U postgres -d fastapi_db -F c -f /tmp/$FILENAME

# Copy from container to host
CONTAINER_ID=$(docker compose -f "$ROOT_DIR/docker-compose.yml" ps -q postgres)
docker cp "$CONTAINER_ID:/tmp/$FILENAME" "$TARGET"

# Cleanup in container
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres rm -f /tmp/$FILENAME

echo "Backup complete: $TARGET"
