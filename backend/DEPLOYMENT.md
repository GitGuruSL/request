Backend Deployment (No SCP)

Overview
- Build and publish Docker images automatically on push to main.
- Server pulls from GHCR and restarts container via SSH action.

CI/CD
- GitHub Actions workflow at .github/workflows/backend-deploy.yml builds Docker image from backend/ and pushes to GHCR.
- Secrets required in repo settings:
  - GHCR_USER: your GitHub username or org (lowercase)
  - GHCR_TOKEN: a GitHub Personal Access Token with read:packages, write:packages
  - DEPLOY_HOST: server IP or hostname
  - DEPLOY_USER: SSH username
  - DEPLOY_SSH_KEY: private key for SSH (PEM contents)

Server setup (one-time)
1) Install Docker
   - Ubuntu: sudo apt-get update && sudo apt-get install -y docker.io
   - Ensure your user is in docker group: sudo usermod -aG docker $USER
2) Create app dir and env file
   - sudo mkdir -p /opt/request-backend && sudo chown $USER:$USER /opt/request-backend
   - Create /opt/request-backend/production.env with required environment variables (copy from backend/.env.example)
3) Open port 3001 on firewall or adjust Nginx to proxy to container

How deployments work
- On push to main: workflow builds image and pushes both tags:
  - ghcr.io/<owner>/request-backend:latest
  - ghcr.io/<owner>/request-backend:<git-sha>
- Deploy uses the immutable <git-sha> tag, binds backend to 127.0.0.1:3001, and runs a /health probe post-deploy.

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
 
<!-- ci: trigger backend build - 2025-08-27 -->
 - GHCR repository owner must be lowercase; the workflow normalizes owner for tags, but set GHCR_USER secret in lowercase to avoid auth issues.
