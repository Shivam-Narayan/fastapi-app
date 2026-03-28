#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 /path/to/backup.sql"
  exit 1
fi

BACKUP_FILE="$1"
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring backup from $BACKUP_FILE"

CONTAINER_ID=$(docker compose -f "$ROOT_DIR/docker-compose.yml" ps -q postgres)
docker cp "$BACKUP_FILE" "$CONTAINER_ID:/tmp/restore_backup.sql"

docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres psql -U postgres -d fastapi_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres pg_restore -U postgres -d fastapi_db --clean --if-exists /tmp/restore_backup.sql

docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres rm -f /tmp/restore_backup.sql

echo "Restore complete"
