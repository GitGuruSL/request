#!/usr/bin/env bash
# Deploy updated backend/routes/driver-verifications.js to a remote server (Bash)
# Prereqs: ssh/scp available, PM2 running the Node app on the server

set -euo pipefail

SERVER="${SERVER:-user@your-ec2-host}"
APP_DIR="${APP_DIR:-/var/www/request/backend}"
PM2_PROCESS="${PM2_PROCESS:-all}"
SKIP_RELOAD="${SKIP_RELOAD:-}" # set to 1 to skip
SKIP_HEALTH="${SKIP_HEALTH:-}" # set to 1 to skip

step(){ echo -e "\e[36m==> $*\e[0m"; }
fail(){ echo -e "\e[31mERROR: $*\e[0m"; exit 1; }

LOCAL_FILE="$(cd "$(dirname "$0")"/.. && pwd)/backend/routes/driver-verifications.js"
[ -f "$LOCAL_FILE" ] || fail "Local file not found: $LOCAL_FILE"

step "Server: $SERVER"
step "AppDir: $APP_DIR"
step "Local file: $LOCAL_FILE"

TIMESTAMP="$(date +%F_%H%M%S)"

step "Backing up remote file..."
ssh "$SERVER" "set -e; cd '$APP_DIR'; cp routes/driver-verifications.js routes/driver-verifications.js.bak_$TIMESTAMP"

step "Uploading driver-verifications.js..."
scp "$LOCAL_FILE" "$SERVER:$APP_DIR/routes/driver-verifications.js"

if [ -z "$SKIP_RELOAD" ]; then
  step "Reloading PM2 ($PM2_PROCESS)"
  if [ "$PM2_PROCESS" = "all" ]; then
    ssh "$SERVER" "pm2 reload all"
  else
    ssh "$SERVER" "pm2 reload '$PM2_PROCESS'"
  fi
fi

if [ -z "$SKIP_HEALTH" ]; then
  step "Checking health endpoint..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --max-time 10 https://api.alphabet.lk/health || true
  fi
  step "Checking public drivers endpoint..."
  curl -fsSL --max-time 10 "https://api.alphabet.lk/api/driver-verifications/public?country=LK&limit=1" || true
fi

step "Done."
