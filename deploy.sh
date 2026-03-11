#!/bin/bash
set -Eeuo pipefail

REPO_DIR="/opt/kram"
BACKEND_DIR="$REPO_DIR/mathquest/backend"
LOG_FILE="/var/log/kram-deploy.log"
HEALTH_RETRIES=40
HEALTH_DELAY_SECONDS=3
DB_READY_RETRIES=60
DB_READY_DELAY_SECONDS=2
API_SERVICE_NAME="api"
DB_SERVICE_NAME="db"
REDIS_SERVICE_NAME="redis"
MIGRATION_NAME="008_camera_share_links.up.sql"
HOST_MIGRATION_FILE="$BACKEND_DIR/migrations/$MIGRATION_NAME"
CONTAINER_MIGRATION_FILE="/docker-entrypoint-initdb.d/$MIGRATION_NAME"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.prod.yml"
LOCAL_COMPOSE_FILE="$REPO_DIR/.run/docker-compose.deploy.local.yml"
CURRENT_STEP="initializing"

if [ -f "$LOCAL_COMPOSE_FILE" ]; then
    COMPOSE_FILE="$LOCAL_COMPOSE_FILE"
fi

log() {
    echo "[$(date)] $*" | tee -a "$LOG_FILE"
}

compose() {
    docker compose --project-directory "$BACKEND_DIR" -f "$COMPOSE_FILE" "$@"
}

api_service_uses_build() {
    awk '
        $1 == "api:" { in_api=1; next }
        in_api && $1 ~ /^[A-Za-z0-9_-]+:$/ { exit }
        in_api && $1 == "build:" { found=1; exit }
        END { exit found ? 0 : 1 }
    ' "$COMPOSE_FILE"
}

trap 'rc=$?; log "Deployment failed during step: $CURRENT_STEP (exit code: $rc)"; exit "$rc"' ERR

log "Starting Kram deployment..."
log "Using compose file: $COMPOSE_FILE"

CURRENT_STEP="change to repository directory"
log "Step 1/7: Changing to repository directory: $REPO_DIR"
cd "$REPO_DIR"

CURRENT_STEP="pull latest code"
log "Step 2/7: Pulling latest code..."
git fetch origin main 2>&1 | tee -a "$LOG_FILE" || git fetch origin master 2>&1 | tee -a "$LOG_FILE"
BRANCH=$(git symbolic-ref --short HEAD)
git pull --ff-only origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"

cd "$BACKEND_DIR"
if [ ! -f "$HOST_MIGRATION_FILE" ]; then
    log "Required migration file is missing: $HOST_MIGRATION_FILE"
    exit 1
fi

if api_service_uses_build; then
    log "Step 2/7: API service uses a local build; latest code will be built during API restart."
else
    CURRENT_STEP="pull latest API image"
    log "Step 2/7: Pulling latest API image..."
    compose pull "$API_SERVICE_NAME" 2>&1 | tee -a "$LOG_FILE"
fi

CURRENT_STEP="start dependencies"
log "Step 3/7: Starting dependency containers: $DB_SERVICE_NAME, $REDIS_SERVICE_NAME"
compose up -d "$DB_SERVICE_NAME" "$REDIS_SERVICE_NAME" 2>&1 | tee -a "$LOG_FILE"

CURRENT_STEP="wait for postgres readiness"
log "Step 4/7: Waiting for Postgres readiness..."
compose exec -T "$DB_SERVICE_NAME" sh -lc "
attempt=0
max_attempts=$DB_READY_RETRIES
until pg_isready -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" >/dev/null 2>&1; do
    attempt=\$((attempt + 1))
    if [ \"\$attempt\" -ge \"\$max_attempts\" ]; then
        echo \"Postgres readiness timed out after \$max_attempts attempts\"
        exit 1
    fi
    echo \"Postgres not ready yet (\$attempt/\$max_attempts)\"
    sleep $DB_READY_DELAY_SECONDS
done
echo \"Postgres is ready\"
" 2>&1 | tee -a "$LOG_FILE"

CURRENT_STEP="run database migration"
log "Step 5/7: Applying migration $MIGRATION_NAME"
compose exec -T "$DB_SERVICE_NAME" sh -lc "
psql -v ON_ERROR_STOP=1 -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" \
    -f \"$CONTAINER_MIGRATION_FILE\"
" 2>&1 | tee -a "$LOG_FILE"
log "Migration $MIGRATION_NAME applied successfully."

CURRENT_STEP="restart API"
log "Step 6/7: Recreating API container..."
if api_service_uses_build; then
    compose up -d --build --force-recreate "$API_SERVICE_NAME" 2>&1 | tee -a "$LOG_FILE"
else
    compose up -d --force-recreate "$API_SERVICE_NAME" 2>&1 | tee -a "$LOG_FILE"
fi

CURRENT_STEP="wait for API readiness"
log "Step 7/7: Waiting for API to be ready..."
LAST_STATE="unknown"
LAST_HEALTH="unknown"
for i in $(seq 1 "$HEALTH_RETRIES"); do
    API_CONTAINER_ID=$(compose ps -q "$API_SERVICE_NAME" 2>/dev/null || true)
    if [ -n "$API_CONTAINER_ID" ]; then
        LAST_STATE=$(docker inspect --format '{{.State.Status}}' "$API_CONTAINER_ID" 2>/dev/null || echo "unknown")
        LAST_HEALTH=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$API_CONTAINER_ID" 2>/dev/null || echo "unknown")

        if [ "$LAST_STATE" = "running" ] && { [ "$LAST_HEALTH" = "healthy" ] || [ "$LAST_HEALTH" = "none" ]; }; then
            log "API container is running (health: $LAST_HEALTH)"
            log "Kram deployment completed successfully."
            exit 0
        fi
    fi

    if [ "$LAST_STATE" = "exited" ] || [ "$LAST_STATE" = "dead" ]; then
        log "API container entered bad state: $LAST_STATE (health: $LAST_HEALTH)"
        exit 1
    fi

    sleep "$HEALTH_DELAY_SECONDS"
done

log "Health check timed out after $((HEALTH_RETRIES * HEALTH_DELAY_SECONDS))s (state: $LAST_STATE, health: $LAST_HEALTH)"
if [ "$LAST_STATE" != "running" ]; then
    log "Deployment failed because API container is not running"
    exit 1
fi

if [ "$LAST_HEALTH" = "unhealthy" ]; then
    log "Deployment failed because API health is unhealthy"
    exit 1
fi

log "Deployment failed because API readiness did not complete before timeout"
exit 1
