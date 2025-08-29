#!/usr/bin/env bash
set -euo pipefail

# Standardized Docker redeploy script for Request backend
# - Uses a single canonical container name
# - Pulls the requested image, replaces the running container, and health-checks

NAME="request-backend-container"                 # Canonical container name
ALT_NAME="request-backend"                       # Legacy/accidental name to clean up
LABEL_KEY="com.gitgurusl.app"
LABEL_VAL="request-backend"
PORT="3001"                                      # Host port to bind
HOST_BIND="127.0.0.1"                            # Bind to localhost by default (behind Nginx)
ENV_FILE="/opt/request-backend/production.env"   # Path to env file on server
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
# Optional GHCR login if credentials are present (useful for private images)
if [[ -n "${GHCR_TOKEN:-}" && -n "${GHCR_USER:-}" ]]; then
  echo "🔐 Logging into GHCR as $GHCR_USER"
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin || true
fi
docker pull "$IMAGE"

# Resolve tag to immutable digest if available
RUNTIME_IMAGE="$IMAGE"
if DIGEST_REF=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null); then
  if [[ -n "$DIGEST_REF" ]]; then
    echo "🔖 Resolved to digest: $DIGEST_REF"
    RUNTIME_IMAGE="$DIGEST_REF"
  fi
fi

echo "🧹 Removing any existing containers for this app (by name, label, or image repo)..."
# Remove by canonical name
docker rm -f "$NAME" >/dev/null 2>&1 || true
# Remove by legacy/accidental name
docker rm -f "$ALT_NAME" >/dev/null 2>&1 || true
# Remove any container with the app label
if docker ps -aq -f "label=${LABEL_KEY}=${LABEL_VAL}" | grep -q .; then
  docker rm -f $(docker ps -aq -f "label=${LABEL_KEY}=${LABEL_VAL}") >/dev/null 2>&1 || true
fi
 # Remove any containers created from the same image repo (any tag) but with a different name
 if docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}' | grep -E "${REPO}[:@]" >/dev/null 2>&1; then
   while read -r ID IMG NM; do
     if [[ "$NM" != "$NAME" ]]; then
       docker rm -f "$ID" >/dev/null 2>&1 || true
     fi
   done < <(docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}' | grep -E "${REPO}[:@]")
 fi

echo "🔒 Ensuring no other container is bound to host port $PORT"
# Remove any container currently publishing host port $PORT if not the canonical name
while read -r CID CNM PRTS; do
  if echo "$PRTS" | grep -E "(0\.0\.0\.0|127\.0\.0\.1):${PORT}->" >/dev/null 2>&1; then
    if [[ "$CNM" != "$NAME" ]]; then
      echo "Killing container $CNM ($CID) occupying host port $PORT"
      docker rm -f "$CID" >/dev/null 2>&1 || true
    fi
  fi
done < <(docker ps --format '{{.ID}} {{.Names}} {{.Ports}}')

echo "🚀 Starting container..."
docker run -d --name "$NAME" \
  --restart unless-stopped \
  --env-file "$ENV_FILE" \
  --label "${LABEL_KEY}=${LABEL_VAL}" \
  -p "$HOST_BIND:$PORT:3001" \
  "$RUNTIME_IMAGE"

echo "⏱️  Waiting for health..."
ATTEMPTS=30
for i in $(seq 1 $ATTEMPTS); do
  if curl -fsS "http://localhost:$PORT/health" >/dev/null 2>&1; then
    echo "✅ Healthy at http://localhost:$PORT/health"
    if [[ "$RUNTIME_IMAGE" == *"@"* ]]; then
      PINNED_REF="${RUNTIME_IMAGE##*@}"
    else
      PINNED_REF="${RUNTIME_IMAGE##*:}"
    fi
    printf "%s" "$PINNED_REF" > /opt/request-backend/last_successful.sha || true
    exit 0
  fi
  sleep 2
done

echo "❌ Health check failed after $((ATTEMPTS*2))s. Showing logs:"
docker logs --tail=200 "$NAME" || true
exit 1
