#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${DEPLOY_HOST:-}"
REMOTE_USER="${DEPLOY_USER:-}"
REMOTE_PATH="${DEPLOY_PATH:-/opt/request-backend}"
PM2_NAME="${PM2_NAME:-request-backend}"
SSH_KEY_PATH="${DEPLOY_KEY_PATH:-}"

if [[ -z "$REMOTE_HOST" || -z "$REMOTE_USER" ]]; then
  echo "Missing DEPLOY_HOST or DEPLOY_USER" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
TGZ="$REPO_ROOT/backend.tgz"

rm -f "$TGZ"

echo "[SCP] Creating archive $TGZ from $BACKEND_DIR"
 tar -czf "$TGZ" \
   --exclude=node_modules \
   --exclude=.git \
   --exclude='*.md' \
   --exclude='.env*' \
   --exclude='uploads' \
   -C "$BACKEND_DIR" .

SCP_ARGS=()
[[ -n "$SSH_KEY_PATH" ]] && SCP_ARGS+=(-i "$SSH_KEY_PATH")
SSH_ARGS=("${SCP_ARGS[@]}")
REMOTE="$REMOTE_USER@$REMOTE_HOST"

echo "[SCP] Uploading $TGZ to $REMOTE:/tmp/request-backend.tgz"
scp "${SCP_ARGS[@]}" "$TGZ" "$REMOTE:/tmp/request-backend.tgz"

read -r -d '' REMOTE_SCRIPT <<'EOS'
set -e
APP_PATH="${REMOTE_PATH}"
sudo mkdir -p "$APP_PATH"
sudo tar -xzf /tmp/request-backend.tgz -C "$APP_PATH" --strip-components=1
cd "$APP_PATH"

if ! command -v node >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y nodejs npm
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y nodejs npm
  fi
fi

npm ci --only=production || npm install --omit=dev

if command -v pm2 >/dev/null 2>&1; then
  pm2 describe "${PM2_NAME}" >/dev/null 2>&1 && pm2 reload "${PM2_NAME}" || pm2 start server.js --name "${PM2_NAME}"
  pm2 save || true
else
  npx pm2 describe "${PM2_NAME}" >/dev/null 2>&1 && npx pm2 reload "${PM2_NAME}" || npx pm2 start server.js --name "${PM2_NAME}"
  npx pm2 save || true
fi

echo "[Remote] Done. Health (if bound): curl -fsS http://127.0.0.1:3001/health || true"
EOS

echo "[SCP] Running remote update via SSH"
ssh "${SSH_ARGS[@]}" "$REMOTE" "$REMOTE_SCRIPT"

rm -f "$TGZ"
echo "[SCP] Deploy complete"
