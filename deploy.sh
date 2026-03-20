#!/bin/bash
# Deploy: push local changes to GitHub, then pull on NAS and restart containers.
set -e

NAS_USER=xelllee
NAS_HOST=192.168.50.184
NAS_PASS="zell@521"
NAS_DIR=/volume1/docker/openclaw
DOCKER=/usr/local/bin/docker

STEPS=4
log()  { echo "[$(date '+%H:%M:%S')] $1"; }
step() { echo; echo "── step $1/$STEPS: $2 ──────────────────────────────"; }
ok()   { echo "[$(date '+%H:%M:%S')] ✓ $1"; }
fail() { echo "[$(date '+%H:%M:%S')] ✗ $1" >&2; exit 1; }

log "starting deploy"
log "branch: $(git rev-parse --abbrev-ref HEAD)  commit: $(git rev-parse --short HEAD)"

# 1. Push to GitHub
step 1 "push to GitHub"
git push origin main && ok "pushed to github.com/BuggyBud/claw" || fail "git push failed"

# 2. Sync .env to NAS
step 2 "sync .env → NAS"
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "cat > $NAS_DIR/.env" < .env \
  && ok ".env synced to $NAS_HOST:$NAS_DIR/.env" \
  || fail ".env sync failed"

# 3. Pull on NAS via git container
step 3 "git pull on NAS"
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "echo '$NAS_PASS' | sudo -S $DOCKER run --rm \
    -v /var/services/homes/$NAS_USER/.ssh:/root/.ssh:ro \
    -v $NAS_DIR/repo:/repo \
    -w /repo \
    alpine/git pull 2>&1" \
  && ok "repo updated on NAS" \
  || fail "git pull on NAS failed"

# 4. Restart openclaw container
step 4 "restart openclaw"
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "echo '$NAS_PASS' | sudo -S $DOCKER-compose -f $NAS_DIR/docker-compose.yml up -d --force-recreate openclaw 2>&1" \
  && ok "openclaw restarted" \
  || fail "docker-compose restart failed"

echo
log "deploy complete → http://$NAS_HOST:3000"
