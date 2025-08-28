#!/usr/bin/env bash
set -euo pipefail

# Standardized Docker redeploy script for Request backend
# - Uses a single canonical container name
# - Pulls the requested image, replaces the running container, and health-checks

NAME="request-backend-container"          # Canonical container name
PORT="3001"                               # Host port to bind
HOST_BIND="127.0.0.1"                      # Bind to localhost by default (behind Nginx)
ENV_FILE="/opt/request-backend/production.env"  # Path to env file on server
REPO="ghcr.io/gitgurusl/request-backend"

usage() {
  echo "Usage: $(basename "$0") <tag-or-full-image> [--public]"
  echo "  <tag-or-full-image>  Either an image tag/sha (e.g., latest or <sha>) or a full image ref"
  echo "  --public              Bind to 0.0.0.0 instead of 127.0.0.1"
}

if [[ ${1:-} == "" ]]; then
  usage
  exit 1
fi

IMAGE_ARG="$1"; shift || true
if [[ ${1:-} == "--public" ]]; then
  HOST_BIND="0.0.0.0"
fi

# Build full image ref if only a tag/sha was provided
if [[ "$IMAGE_ARG" == *":"* && "$IMAGE_ARG" == ghcr.io/* ]]; then
  IMAGE="$IMAGE_ARG"
else
  IMAGE="$REPO:$IMAGE_ARG"
fi

echo "➡️  Deploying image: $IMAGE"
echo "➡️  Container name: $NAME"
echo "➡️  Host bind:      $HOST_BIND:$PORT -> 3001"
echo "➡️  Env file:       $ENV_FILE"

echo "📥 Pulling image..."
docker pull "$IMAGE"

echo "🧹 Removing any existing container named $NAME (if present)..."
docker rm -f "$NAME" >/dev/null 2>&1 || true

echo "🚀 Starting container..."
docker run -d --name "$NAME" \
  --restart unless-stopped \
  --env-file "$ENV_FILE" \
  -p "$HOST_BIND:$PORT:3001" \
  "$IMAGE"

echo "⏱️  Waiting for health..."
ATTEMPTS=30
for i in $(seq 1 $ATTEMPTS); do
  if curl -fsS "http://localhost:$PORT/health" >/dev/null 2>&1; then
    echo "✅ Healthy at http://localhost:$PORT/health"
    exit 0
  fi
  sleep 2
done

echo "❌ Health check failed after $((ATTEMPTS*2))s. Showing logs:"
docker logs --tail=200 "$NAME" || true
exit 1
