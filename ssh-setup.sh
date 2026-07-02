#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"
PUB_FILE="$SSH_DIR/id_rsa.pub"

# Step 1: generate key pair if not exists
if [ ! -f "$KEY_FILE" ]; then
    echo "==> Generating SSH key pair..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -q
    echo "    Generated: $KEY_FILE"
else
    echo "==> SSH key already exists, skipping generation"
fi

# Step 2: upload public key
echo "==> Uploading public key..."
UPLOAD_SCRIPT="/home/lumin/.claude/skills/file-uploader/scripts/upload.py"
PUB_URL=$("$UPLOAD_SCRIPT" "$PUB_FILE" 2>/dev/null | grep "^Uploaded: " | sed 's/^Uploaded: //')
echo "    Uploaded: $PUB_URL"

# Step 3: print command to append to authorized_keys
FILENAME=$(basename "$PUB_FILE")
echo ""
echo "=============================================="
echo "Run this on cloudcone.moonchan.xyz:"
echo "=============================================="
echo "curl -sL \"$PUB_URL\" >> ~/.ssh/authorized_keys"
echo "=============================================="
