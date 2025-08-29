#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/var/www/request-backend"
if command -v pm2 >/dev/null 2>&1; then
  pm2 stop request-backend || true
fi

# Stop and remove docker containers that may be running the app
NAME="request-backend-container"
ALT_NAME="request-backend"
LABEL_KEY="com.gitgurusl.app"
LABEL_VAL="request-backend"

if command -v docker >/dev/null 2>&1; then
  echo "[CodeDeploy] Stopping Docker containers for $LABEL_VAL"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker rm -f "$ALT_NAME" >/dev/null 2>&1 || true
  if docker ps -aq -f "label=${LABEL_KEY}=${LABEL_VAL}" | grep -q .; then
    docker rm -f $(docker ps -aq -f "label=${LABEL_KEY}=${LABEL_VAL}") >/dev/null 2>&1 || true
  fi
  # Free host port 3001 if occupied by any container
  PORT=3001
  while read -r CID CNM PRTS; do
    if echo "$PRTS" | grep -E "(0\.0\.0\.0|127\.0\.0\.1):${PORT}->" >/dev/null 2>&1; then
      echo "[CodeDeploy] Killing container $CNM ($CID) occupying host port $PORT"
      docker rm -f "$CID" >/dev/null 2>&1 || true
    fi
  done < <(docker ps --format '{{.ID}} {{.Names}} {{.Ports}}')
fi
