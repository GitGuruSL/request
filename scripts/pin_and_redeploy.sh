#!/usr/bin/env bash
set -euo pipefail

# Pin to immutable digest and redeploy via /opt/request-backend/redeploy.sh
# Usage: pin_and_redeploy.sh [tag-or-full-ref]
#  - If omitted, defaults to ghcr.io/gitgurusl/request-backend:latest
#  - Accepts GHCR_USER/GHCR_TOKEN for private images

REF_INPUT="${1:-ghcr.io/gitgurusl/request-backend:latest}"
if [[ "$REF_INPUT" != ghcr.io/* ]]; then
  REF="ghcr.io/gitgurusl/request-backend:${REF_INPUT}"
else
  REF="$REF_INPUT"
fi

echo "[pin] Resolving digest for $REF"
if [[ -n "${GHCR_TOKEN:-}" && -n "${GHCR_USER:-}" ]]; then
  echo "[pin] Logging into GHCR as $GHCR_USER"
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null 2>&1 || true
fi

docker pull "$REF" >/dev/null 2>&1 || true
DIG=$(docker image inspect "$REF" --format '{{index .RepoDigests 0}}' || true)
if [[ -z "${DIG:-}" ]]; then
  echo "[pin] Failed to resolve digest for $REF" >&2
  exit 1
fi

case "$DIG" in
  ghcr.io/*@sha256:*) ;;
  *) echo "[pin] Invalid digest: $DIG" >&2; exit 1;;
 esac

echo "[pin] Redeploying $DIG"
if [[ ! -x /opt/request-backend/redeploy.sh ]]; then
  echo "[pin] /opt/request-backend/redeploy.sh not found or not executable" >&2
  exit 1
fi

/opt/request-backend/redeploy.sh "$DIG"

echo "$DIG" | sudo tee /opt/request-backend/last_successful.sha >/dev/null

echo "[pin] Done. Active image: $DIG"
