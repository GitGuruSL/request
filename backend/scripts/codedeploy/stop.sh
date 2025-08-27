#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/var/www/request-backend"
if command -v pm2 >/dev/null 2>&1; then
  pm2 stop request-backend || true
fi
