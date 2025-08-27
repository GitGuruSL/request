param(
  [string]$RemoteHost = $env:DEPLOY_HOST,
  [string]$User = $env:DEPLOY_USER,
  [string]$Path = $(if ($env:DEPLOY_PATH) { $env:DEPLOY_PATH } else { '/opt/request-backend' }),
  [string]$Pm2  = $(if ($env:PM2_NAME) { $env:PM2_NAME } else { 'request-backend' }),
  [string]$Key  = $env:DEPLOY_KEY_PATH
)

if (-not $RemoteHost -or -not $User) {
  Write-Error "Missing Host/User. Provide -Host and -User or set DEPLOY_HOST/DEPLOY_USER env vars."
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$backendDir = Join-Path $repoRoot 'backend'
if (-not (Test-Path $backendDir)) { Write-Error "Backend folder not found: $backendDir"; exit 1 }

$tgz = Join-Path $repoRoot 'backend.tgz'
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

$remoteScript = @"
set -e
echo "[Remote] Ensure app path: $Path"
sudo mkdir -p "$Path"
echo "[Remote] Extracting archive"
sudo tar -xzf /tmp/request-backend.tgz -C "$Path" --strip-components=1
cd "$Path"
echo "[Remote] Installing Node if missing"
if ! command -v node >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y nodejs npm
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y nodejs npm
  fi
fi
echo "[Remote] Installing production deps"
npm ci --only=production || npm install --omit=dev
echo "[Remote] Restarting with PM2 ($Pm2)"
if command -v pm2 >/dev/null 2>&1; then
  pm2 describe "$Pm2" >/dev/null 2>&1 && pm2 reload "$Pm2" || pm2 start server.js --name "$Pm2"
  pm2 save || true
else
  npx pm2 describe "$Pm2" >/dev/null 2>&1 && npx pm2 reload "$Pm2" || npx pm2 start server.js --name "$Pm2"
  npx pm2 save || true
fi
echo "[Remote] Done. Health (if bound): curl -fsS http://127.0.0.1:3001/health || true"
"@

Write-Host "[SCP] Running remote update via SSH"
& ssh @sshKeyArg "$remote" "$remoteScript"
if ($LASTEXITCODE -ne 0) { Write-Error "ssh failed ($LASTEXITCODE)"; exit $LASTEXITCODE }

Remove-Item $tgz -Force
Write-Host "[SCP] Deploy complete"
