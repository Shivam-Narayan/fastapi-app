#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/alembic.ini" ]; then
  echo "alembic.ini not found in $SCRIPT_DIR" >&2
  exit 1
fi

cd "$SCRIPT_DIR"

# Migrate to latest revision
alembic -c alembic.ini upgrade head

echo "Database migration finished."
