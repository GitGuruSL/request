param(
  [string]$RemoteHost = $env:DEPLOY_HOST,
  [string]$User = $env:DEPLOY_USER,
  [string]$Path = $(if ($env:DEPLOY_PATH) { $env:DEPLOY_PATH } else { '/opt/request-backend' }),
  [string]$Pm2  = $(if ($env:PM2_NAME) { $env:PM2_NAME } else { 'request-backend' }),
  [string]$Key  = $env:DEPLOY_KEY_PATH,
  [switch]$Mirror
)

if (-not $RemoteHost -or -not $User) {
  Write-Error "Missing Host/User. Provide -Host and -User or set DEPLOY_HOST/DEPLOY_USER env vars."
  exit 1
}

$backendDir = Resolve-Path (Join-Path $PSScriptRoot '..')
if (-not (Test-Path $backendDir)) { Write-Error "Backend folder not found: $backendDir"; exit 1 }

$tgz = Join-Path $env:TEMP 'backend.tgz'
if (Test-Path $tgz) { Remove-Item $tgz -Force }

Write-Host "[SCP] Creating archive $tgz from $backendDir"
tar -czf "$tgz" `
  --exclude=node_modules `
  --exclude=.git `
  --exclude='*.md' `
  --exclude='.env*' `
  --exclude='uploads' `
  -C "$backendDir" .
if ($LASTEXITCODE -ne 0) { Write-Error "tar failed ($LASTEXITCODE)"; exit $LASTEXITCODE }

$scpKeyArg = if ($Key) { @('-i', $Key) } else { @() }
$sshKeyArg = $scpKeyArg
$remote = "$User@$RemoteHost"

Write-Host "[SCP] Uploading $tgz to ${remote}:/tmp/request-backend.tgz"
& scp @scpKeyArg "$tgz" "${remote}:/tmp/request-backend.tgz"
if ($LASTEXITCODE -ne 0) { Write-Error "scp failed ($LASTEXITCODE)"; exit $LASTEXITCODE }

$remoteScript = @'
set -e

echo "[Remote] Ensure app path: ${APP_PATH}"
sudo mkdir -p "${APP_PATH}"
echo "[Remote] Extracting archive"
if [ "${MIRROR}" = "True" ] || [ "${MIRROR}" = "true" ]; then
  echo "[Remote] Mirror mode: cleaning stale files (preserving env, uploads, node_modules, deploy)"
  for f in "${APP_PATH}"/*; do
    bn="$(basename "$f")"
    case " $bn " in
      ' .env '|' .env.rds '|' production.env '|' uploads '|' node_modules '|' deploy ')
        echo "[Remote] Preserving $bn" ;;
      *)
        echo "[Remote] Removing $f"; sudo rm -rf "$f" ;;
    esac
  done
fi
sudo tar -xzf /tmp/request-backend.tgz -C "${APP_PATH}" --strip-components=1
cd "${APP_PATH}"
echo "[Remote] Fixing permissions"
sudo chown -R "$USER":"$USER" "${APP_PATH}"
echo "[Remote] Installing Node if missing"
if ! command -v node >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y nodejs npm
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y nodejs npm
  fi
fi
echo "[Remote] Installing production deps"
# Clean potentially root-owned node_modules to avoid EACCES issues
if [ -d node_modules ]; then
  echo "[Remote] Removing existing node_modules to avoid permission issues"
  sudo rm -rf node_modules
fi
# Prefer modern omit=dev flag
npm ci --omit=dev || npm install --omit=dev
echo "[Remote] Restarting with PM2 (${PM2_NAME})"
if command -v pm2 >/dev/null 2>&1; then
  pm2 describe "${PM2_NAME}" >/dev/null 2>&1 && pm2 reload "${PM2_NAME}" || pm2 start server.js --name "${PM2_NAME}"
  pm2 save || true
else
  npx pm2 describe "${PM2_NAME}" >/dev/null 2>&1 && npx pm2 reload "${PM2_NAME}" || npx pm2 start server.js --name "${PM2_NAME}"
  npx pm2 save || true
fi
echo "[Remote] Done. Health (if bound): curl -fsS http://127.0.0.1:3001/health || true"
'@

Write-Host "[SCP] Running remote update via SSH"
# Normalize to LF and send as base64 to avoid CRLF parsing issues on remote
$remoteScriptLF = $remoteScript -replace "`r?`n","`n"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($remoteScriptLF)
$b64 = [Convert]::ToBase64String($bytes)
$envAssign = "APP_PATH='${Path}' PM2_NAME='${Pm2}' MIRROR='${($Mirror.IsPresent)}'"
$exec = "echo $b64 | base64 -d > /tmp/request-deploy.sh && chmod +x /tmp/request-deploy.sh && $envAssign bash /tmp/request-deploy.sh"
& ssh @sshKeyArg "$remote" "$exec"
if ($LASTEXITCODE -ne 0) { Write-Error "ssh failed ($LASTEXITCODE)"; exit $LASTEXITCODE }

Remove-Item $tgz -Force
Write-Host "[SCP] Deploy complete"
