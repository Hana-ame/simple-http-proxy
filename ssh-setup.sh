#!/usr/bin/env bash
set -euo pipefail

urlencode() {
  local s="$1" i c hex
  for ((i=0; i<${#s}; i++)); do
    c="${s:$i:1}"
    [[ "$c" =~ [a-zA-Z0-9._-] ]] && printf '%s' "$c" || {
      printf -v hex '%02X' "'${c:0:1}"
      printf '%%%s' "$hex"
    }
  done
}

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"
PUB_FILE="$SSH_DIR/id_rsa.pub"
API_URL="https://upload.moonchan.xyz/api/upload"

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
FILENAME=$(basename "$PUB_FILE")
CONTENT_TYPE=$(file --mime-type -b "$PUB_FILE")
ENCODED_NAME=$(urlencode "$FILENAME")
RESPONSE=$(curl -s -X PUT \
    -H "Content-Type: $CONTENT_TYPE" \
    -H "X-File-Name: $ENCODED_NAME" \
    --data-binary @"$PUB_FILE" \
    "$API_URL")
FILE_ID=$(echo "$RESPONSE" | grep -oP '"id":"\K[^"]+')
PUB_URL="https://upload.moonchan.xyz/api/$FILE_ID/$FILENAME"
echo "    Uploaded: $PUB_URL"

# Step 3: print command to append to authorized_keys
echo ""
echo "=============================================="
echo "Run this on cloudcone.moonchan.xyz:"
echo "=============================================="
echo "curl -sL \"$PUB_URL\" >> ~/.ssh/authorized_keys"
echo "=============================================="
