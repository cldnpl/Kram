# Automated Deployment Setup

This guide covers the production backend deployment flow for `main`.

Production is currently updated by a server-side webhook, not GitHub Actions. The webhook runs `/opt/kram/deploy.sh`, which automatically:

1. pulls the latest code or image for the current deploy mode,
2. starts `db` and `redis`,
3. waits for Postgres readiness,
4. applies idempotent SQL migrations such as `migrations/008_camera_share_links.up.sql`,
5. recreates `api` only after the migration succeeds.

No manual `psql` command is required during a normal webhook deploy.

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

After the first boot, subsequent schema changes are applied automatically by the webhook deploy script before `api` is restarted.

## 4. GitHub Container Registry Access

The workflow uses GitHub Container Registry (ghcr.io). Make sure your repository has:

1. **Package write permissions**: Go to repo → Settings → Actions → General → Workflow permissions → Select "Read and write permissions"

2. **Package visibility** (optional): After first build, go to your profile → Packages → mathquest-backend → Package settings → Change visibility if needed

## 5. How It Works

1. You push code to `main` branch
2. The webhook on the server receives the push event
3. The server pulls the latest code and, when applicable, the latest API image
4. The deploy script starts `db` and `redis`
5. The deploy script waits until Postgres reports ready
6. The deploy script runs the SQL migration non-interactively inside the `db` container
7. The deploy script recreates `api` and waits for it to become ready

## 6. Checking Deployment Status

- **Webhook service logs**: `journalctl -u kram-webhook.service -f`
- **Deploy log**: `tail -f /var/log/kram-deploy.log`
- **Server logs**: `docker logs mathquest-api -f`
- **All containers**: `docker ps`

## 7. Manual Deployment (if needed)

```bash
/opt/kram/deploy.sh
```

If you must bypass the webhook entirely, follow the same dependency -> Postgres readiness -> migration -> API recreate sequence used by `/opt/kram/deploy.sh`.

## 8. Rollback

To rollback to a specific version:

```bash
# Find the commit SHA you want to rollback to
docker pull ghcr.io/YOUR_GITHUB_USERNAME/mathquest-backend:COMMIT_SHA
docker compose -f docker-compose.prod.yml up -d --force-recreate api
```

Schema changes from idempotent migrations remain applied. If a deploy fails during the migration step, the script exits before recreating `api`, so the previous API container keeps serving traffic.

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
