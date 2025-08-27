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

$cmd = "cd /opt/request-backend && node ./scripts/run-sql-migration.js ./migration/20250827_subscriptions.sql"
Write-Host "[SSH] Running migration on $remote"
& ssh @sshArgs $remote $cmd
if ($LASTEXITCODE -ne 0) { Write-Error "Migration failed ($LASTEXITCODE)"; exit $LASTEXITCODE }
Write-Host "[SSH] Migration completed"
