#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3001}"
ATTEMPTS=15

echo "[CodeDeploy] Validating service health on port $PORT"
for i in $(seq 1 $ATTEMPTS); do
  if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    echo "[CodeDeploy] ✅ Healthy"
    exit 0
  fi
  sleep 2
done

echo "[CodeDeploy] ❌ Health check failed"
exit 1
