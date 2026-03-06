# Automated Deployment Setup

This guide sets up automatic deployment when you push to the `main` branch.

## 1. GitHub Repository Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name | Description |
|-------------|-------------|
| `SERVER_HOST` | Your server's IP address (e.g., `123.456.789.0`) |
| `SERVER_USER` | SSH username (e.g., `root` or `deploy`) |
| `SERVER_SSH_KEY` | Your private SSH key (the entire content of `~/.ssh/id_rsa` or `id_ed25519`) |

## 2. Server Setup (One-time)

SSH into your server and run:

```bash
# Create project directory
mkdir -p ~/mathquest/migrations

# Copy your migrations folder to the server
# From your local machine:
# scp -r backend/migrations/* user@server:~/mathquest/migrations/

# Create .env file on the server
cd ~/mathquest
nano .env
```

Paste your environment variables (see `.env.example` for template):

```env
GITHUB_OWNER=your-github-username
POSTGRES_USER=mathquest
POSTGRES_PASSWORD=change-this-to-a-secure-password
POSTGRES_DB=mathquest
PORT=8080
ENV=production
CLAUDE_API_KEY=your-claude-api-key
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
CAMERA_DAILY_LIMIT=5
```

Copy the production docker-compose file to your server:

```bash
# From your local machine:
scp backend/docker-compose.prod.yml user@server:~/mathquest/docker-compose.prod.yml
```

If you have Firebase credentials:

```bash
# Copy Firebase credentials to server
scp path/to/firebase-credentials.json user@server:~/mathquest/firebase-credentials.json
```

## 3. First Deployment

On your server, start the databases first:

```bash
cd ~/mathquest
docker compose -f docker-compose.prod.yml up -d db redis
```

Wait for databases to be ready, then start the API:

```bash
docker compose -f docker-compose.prod.yml up -d
```

## 4. GitHub Container Registry Access

The workflow uses GitHub Container Registry (ghcr.io). Make sure your repository has:

1. **Package write permissions**: Go to repo → Settings → Actions → General → Workflow permissions → Select "Read and write permissions"

2. **Package visibility** (optional): After first build, go to your profile → Packages → mathquest-backend → Package settings → Change visibility if needed

## 5. How It Works

1. You push code to `main` branch
2. GitHub Actions builds a Docker image
3. Image is pushed to GitHub Container Registry
4. Workflow SSHs into your server
5. Server pulls the new image and restarts the container

## 6. Checking Deployment Status

- **GitHub Actions**: Check the "Actions" tab in your repo
- **Server logs**: `docker logs mathquest-api -f`
- **All containers**: `docker ps`

## 7. Manual Deployment (if needed)

```bash
cd ~/mathquest
docker pull ghcr.io/YOUR_GITHUB_USERNAME/mathquest-backend:latest
docker compose -f docker-compose.prod.yml up -d --force-recreate api
```

## 8. Rollback

To rollback to a specific version:

```bash
# Find the commit SHA you want to rollback to
docker pull ghcr.io/YOUR_GITHUB_USERNAME/mathquest-backend:COMMIT_SHA
docker compose -f docker-compose.prod.yml up -d --force-recreate api
```

## Troubleshooting

**SSH connection failed:**
- Ensure your SSH key is added to `~/.ssh/authorized_keys` on the server
- Check that the server allows SSH connections

**Image pull failed:**
- Ensure `GITHUB_TOKEN` has package read/write permissions
- Check if the package is private and authentication is correct

**Container won't start:**
- Check logs: `docker logs mathquest-api`
- Verify `.env` file has all required variables
- Ensure databases are running: `docker ps`
