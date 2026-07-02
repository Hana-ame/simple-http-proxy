#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building goproxy..."
go build -o goproxy .

echo "==> Starting proxy on :1080"
exec ./goproxy
