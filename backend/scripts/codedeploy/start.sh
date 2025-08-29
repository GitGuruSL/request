#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/request-backend"
DEPLOY_DIR="$APP_DIR/deploy"

IMAGE_TAG="${IMAGE_TAG:-latest}"
PUBLIC_BIND="${PUBLIC_BIND:-}"

echo "[CodeDeploy] Starting app using deploy/redeploy.sh with tag: $IMAGE_TAG"
chmod +x "$DEPLOY_DIR/redeploy.sh"
if [[ -n "$PUBLIC_BIND" ]]; then
  "$DEPLOY_DIR/redeploy.sh" "$IMAGE_TAG" --public
else
  "$DEPLOY_DIR/redeploy.sh" "$IMAGE_TAG"
fi

echo "[CodeDeploy] Start complete"
