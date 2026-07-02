#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Building goproxy..."
go build -o goproxy .

echo "==> Starting proxy on :1080 (background)"
nohup ./goproxy > goproxy.log 2>&1 &
echo "$!" > goproxy.pid
echo "PID: $(cat goproxy.pid)"
