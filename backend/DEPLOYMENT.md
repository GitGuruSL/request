Backend Deployment (No SCP)

Overview
- Build and publish Docker images automatically on push to main.
- Server pulls from GHCR and restarts container via SSH action.

CI/CD
- GitHub Actions workflow at `.github/workflows/backend-deploy.yml` builds Docker image from `backend/` and pushes to GHCR.
- Image tags:
  - `ghcr.io/<owner-lower>/request-backend:latest`
  - `ghcr.io/<owner-lower>/request-backend:<git-sha>` (deploys use the immutable sha tag)
- Required repo secrets:
  - `GHCR_USER` (lowercase GitHub username or org) and `GHCR_TOKEN` (PAT with `read:packages`, `write:packages`) — used for image push; if not set, workflow falls back to `GITHUB_TOKEN` for GHCR push.
  - `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY` — used by SSH deploy.
- GHCR visibility: if your GHCR package is private, the server must also authenticate (workflow will docker login with `GHCR_USER/TOKEN` on the server if provided). If public, server can pull anonymously.

Server setup (one-time)
1) Install Docker
   - Ubuntu: sudo apt-get update && sudo apt-get install -y docker.io
   - Ensure your user is in docker group: sudo usermod -aG docker $USER
2) Create app dir and env file
   - sudo mkdir -p /opt/request-backend && sudo chown $USER:$USER /opt/request-backend
   - Create /opt/request-backend/production.env with required environment variables (copy from backend/.env.example)
3) Keep container bound to localhost and proxy via Nginx
   - Container is started with: `-p 127.0.0.1:3001:3001` (not exposed publicly)
   - Configure Nginx to proxy your domain (e.g., `/api`) to `http://127.0.0.1:3001`

How deployments work
- On push to main: workflow builds image and pushes `latest` and `<git-sha>` to GHCR (owner normalized to lowercase).
- Deploy pulls the `<git-sha>` tag on the server, runs the container bound to `127.0.0.1:3001`, then probes `/health` up to 30 times. On success, the sha is recorded to `/opt/request-backend/last_successful.sha` for rollback.

Local development
- docker compose -f backend/docker-compose.yml up --build

Rollbacks
- SSH to server and run:
  docker pull ghcr.io/<owner>/request-backend:<old-sha>
  docker rm -f request-backend
  docker run -d --name request-backend --restart unless-stopped --env-file /opt/request-backend/production.env -p 127.0.0.1:3001:3001 ghcr.io/<owner>/request-backend:<old-sha>

Notes
- Ensure production.env matches the variables consumed by backend/server.js.
- For Nginx TLS, keep Nginx on host and proxy to http://localhost:3001.
 - If `/health` depends on DB and the database is unreachable, deployment will fail and rollback. Verify DB access and credentials in `production.env` before retrying.
 - If GHCR pulls fail on server, either set `GHCR_USER/GHCR_TOKEN` repo secrets (server docker login is attempted) or make the GHCR package public.

<!-- ci: trigger backend build - 2025-08-27 -->
 - GHCR repository owner must be lowercase; the workflow normalizes owner for tags, but set GHCR_USER secret in lowercase to avoid auth issues.

Simple SCP deployment (no CI)

Windows PowerShell
```powershell
$env:DEPLOY_HOST = "your.server.ip"     # e.g., 203.0.113.10
$env:DEPLOY_USER = "ubuntu"             # your SSH user
$env:DEPLOY_KEY_PATH = "$env:USERPROFILE\.ssh\request_deploy"  # optional key path
cd $PSScriptRoot
npm run deploy:scp:ps --prefix ./backend
```

Bash (macOS/Linux)
```bash
export DEPLOY_HOST=your.server.ip   # e.g., 203.0.113.10
export DEPLOY_USER=ubuntu           # your SSH user
export DEPLOY_KEY_PATH=$HOME/.ssh/request_deploy  # optional
(cd backend && npm run deploy:scp:sh)
```

What it does
- Creates a tarball of `backend/` (excluding node_modules, .env*, uploads, .git).
- Copies it to the server at `/tmp/request-backend.tgz`.
- Extracts to `/opt/request-backend` (override with DEPLOY_PATH).
- Installs production deps and restarts/starts via PM2 (`PM2_NAME` env to change name).

<!-- ci: trigger backend deploy - 2025-08-27T00:00Z -->
