param(
  [string]$RemoteHost = $env:DEPLOY_HOST,
  [string]$User = $env:DEPLOY_USER,
  [string]$Key  = $env:DEPLOY_KEY_PATH,
  [string]$RemotePath = $(if ($env:DEPLOY_PATH) { $env:DEPLOY_PATH } else { '/opt/request-backend' }),
  [string]$OutDir = $(Join-Path $PSScriptRoot '..' 'remote-snapshot')
)

if (-not $RemoteHost -or -not $User) { Write-Error "Missing Host/User"; exit 1 }

$sshKeyArg = if ($Key) { @('-i', $Key) } else { @() }
$remote = "$User@$RemoteHost"

Write-Host "[SCP] Snapshotting ${remote}:${RemotePath} to ${OutDir}"
if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$remoteScript = @'
set -e
cd "$REMOTE_PATH"
# create a tar excluding heavy/runtime bits
EXCLUDE=(
  '--exclude=node_modules'
  '--exclude=uploads'
  '--exclude=.git'
)
TARFILE="/tmp/remote-backend-snapshot.tgz"
 tar -czf "$TARFILE" "${EXCLUDE[@]}" -C "$REMOTE_PATH" .
 echo "$TARFILE"
'@

# Build a small runner to accept var
$runner = @("REMOTE_PATH='${RemotePath}' bash -lc '" + ($remoteScript -replace "'", "'\\''") + "'") -join ''

# Ask remote to produce tar and print path
$tarPath = & ssh @sshKeyArg $remote $runner
if ($LASTEXITCODE -ne 0 -or -not $tarPath) { Write-Error "Remote snapshot failed"; exit 1 }

# Copy it down
& scp @sshKeyArg "${remote}:${tarPath}" (Join-Path $OutDir 'remote-backend-snapshot.tgz')
if ($LASTEXITCODE -ne 0) { Write-Error "scp download failed"; exit $LASTEXITCODE }

# Extract
 tar -xzf (Join-Path $OutDir 'remote-backend-snapshot.tgz') -C $OutDir
 Remove-Item (Join-Path $OutDir 'remote-backend-snapshot.tgz') -Force

Write-Host "[SCP] Snapshot saved in $OutDir"
