#!/usr/bin/env bash
set -euo pipefail

echo "[CodeDeploy] Installing dependencies (Docker)"

if ! command -v docker >/dev/null 2>&1; then
  echo "[CodeDeploy] Docker not found. Installing..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://get.docker.com | sh
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y docker || sudo amazon-linux-extras install -y docker
  else
    echo "[CodeDeploy] No supported package manager found (apt-get/yum)."
  fi
fi

if systemctl list-unit-files | grep -q docker.service; then
  sudo systemctl enable docker || true
  sudo systemctl start docker || true
fi

sudo usermod -aG docker "$USER" || true

# Optional GHCR login if variables provided
if [[ -n "${GHCR_TOKEN:-}" && -n "${GHCR_USER:-}" ]]; then
  echo "[CodeDeploy] Logging into GHCR as $GHCR_USER"
  echo "$GHCR_TOKEN" | sudo -E docker login ghcr.io -u "$GHCR_USER" --password-stdin || true
fi

# Ensure app state dir and env file
APP_STATE="/opt/request-backend"
sudo mkdir -p "$APP_STATE"

SRC_ENV="/var/www/request-backend/deploy/production.env"
DST_ENV="$APP_STATE/production.env"
if [[ -f "$SRC_ENV" && ! -f "$DST_ENV" ]]; then
  echo "[CodeDeploy] Seeding env file from artifact"
  sudo cp "$SRC_ENV" "$DST_ENV"
fi

echo "[CodeDeploy] Install dependencies done."
