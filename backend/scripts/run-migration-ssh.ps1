param(
  [string]$RemoteHost = $env:DEPLOY_HOST,
  [string]$User = $env:DEPLOY_USER,
  [string]$Key  = $env:DEPLOY_KEY_PATH
)

if (-not $RemoteHost -or -not $User) {
  Write-Error "Missing Host/User. Set DEPLOY_HOST and DEPLOY_USER."
  exit 1
}

$sshArgs = @()
if ($Key) { $sshArgs += @('-i', $Key) }
$remote = "$User@$RemoteHost"

Write-Host "[SSH] Running migration on $remote"
$script = @"
set -e
cd /opt/request-backend
# Ensure dos2unix is available and normalize env files (handles CRLF)
if ! command -v dos2unix >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y >/dev/null 2>&1 || true
    sudo apt-get install -y dos2unix >/dev/null 2>&1 || true
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y dos2unix >/dev/null 2>&1 || true
  fi
fi
for f in production.env deploy/production.env .env.rds; do
  if [ -f "$f" ]; then
    dos2unix "$f" >/dev/null 2>&1 || true
    sed -i 's/\r$//' "$f" || true
  fi
done
if [ -f production.env ]; then
  set -a
  . ./production.env
  set +a
fi
if [ -f deploy/production.env ]; then
  awk '{ sub(/\r$/, ""); print }' deploy/production.env > /tmp/prod.env
  set -a
  . /tmp/prod.env
  set +a
fi
if [ -f .env.rds ]; then
  set -a
  . ./.env.rds
  set +a
fi
node ./scripts/run-sql-migration.js ./migration/20250827_subscriptions.sql
"@
# Normalize to LF and send via base64
$scriptLF = $script -replace "`r?`n","`n"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptLF)
$b64 = [Convert]::ToBase64String($bytes)
$exec = "echo $b64 | base64 -d > /tmp/run-migrate.sh && chmod +x /tmp/run-migrate.sh && bash /tmp/run-migrate.sh"
& ssh @sshArgs $remote $exec
if ($LASTEXITCODE -ne 0) { Write-Error "Migration failed ($LASTEXITCODE)"; exit $LASTEXITCODE }
Write-Host "[SSH] Migration completed"
