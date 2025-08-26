#!/usr/bin/env bash
set -euo pipefail

# Quick installer for request-backend deploy packages on EC2
# Usage:
#   ./deploy/install-package.sh [path-to-package]
#
# If no argument provided, defaults to ~/request-backend-deploy.tar.gz (or .zip fallback)

APP_NAME="request-backend"
APP_DIR="/var/www/request-backend"
PKG_PATH="${1:-$HOME/request-backend-deploy.tar.gz}"

echo "📦 Installing package: $PKG_PATH"
if [ ! -f "$PKG_PATH" ]; then
  if [ -f "$HOME/request-backend-deploy.zip" ]; then
    PKG_PATH="$HOME/request-backend-deploy.zip"
  else
    echo "❌ Package not found. Provide path to request-backend-deploy.tar.gz or .zip" >&2
    exit 1
  fi
fi

TMP_DIR="${APP_DIR}.new"
BACKUP_DIR="${APP_DIR}.$(date +%Y%m%d-%H%M%S).bak"

sudo mkdir -p "$APP_DIR"
sudo chown -R "$USER":"$USER" "$APP_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "🗜️ Extracting package..."
case "$PKG_PATH" in
  *.tar.gz)
    tar -xzf "$PKG_PATH" -C "$TMP_DIR"
    ;;
  *.zip)
    if ! command -v unzip >/dev/null 2>&1; then
      echo "📦 Installing unzip..."
      sudo apt-get update -y && sudo apt-get install -y unzip
    fi
    unzip -qo "$PKG_PATH" -d "$TMP_DIR"
    ;;
  *)
    echo "❌ Unsupported package type: $PKG_PATH" >&2
    exit 1
    ;;
esac

echo "🧩 Installing production dependencies..."
pushd "$TMP_DIR" >/dev/null
if command -v npm >/dev/null 2>&1; then
  # Prefer npm ci if lockfile exists
  if [ -f package-lock.json ]; then
    npm ci --omit=dev
  else
    npm install --production
  fi
else
  echo "❌ npm not found. Please install Node.js/npm first." >&2
  exit 1
fi

# Preserve existing environment file
if [ -f "$APP_DIR/.env.rds" ] && [ ! -f "$TMP_DIR/.env.rds" ]; then
  cp "$APP_DIR/.env.rds" "$TMP_DIR/.env.rds"
  echo "✅ Preserved existing .env.rds"
fi
popd >/dev/null

echo "🔁 Swapping directories (with backup)..."
if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
  sudo mv "$APP_DIR" "$BACKUP_DIR"
fi
sudo mv "$TMP_DIR" "$APP_DIR"
sudo chown -R "$USER":"$USER" "$APP_DIR"

echo "🚀 Restarting PM2 app: $APP_NAME"
if command -v pm2 >/dev/null 2>&1; then
  pm2 start "$APP_DIR/server.js" --name "$APP_NAME" || true
  pm2 restart "$APP_NAME" --update-env
  pm2 save
else
  echo "⚠️ PM2 not found; skipping restart. Start app manually with: pm2 start $APP_DIR/server.js --name $APP_NAME"
fi

echo "✅ Deploy complete. Current PM2 status:"
pm2 status | sed -n '1,10p' || true

echo "🔎 Health check:"
curl -sk https://api.alphabet.lk/health | head -c 400 | cat || true
echo
