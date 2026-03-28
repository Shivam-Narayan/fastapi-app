#!/usr/bin/env bash
set -euo pipefail

# Simple self-signed cert generator for local development.
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CERT_DIR="$ROOT_DIR/certs"
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/tls.key" \
    -out "$CERT_DIR/tls.crt" \
    -subj "/CN=localhost/O=FastAPI-Learn"

echo "Generated $CERT_DIR/tls.crt and $CERT_DIR/tls.key"
