#!/bin/bash
# Deploy: push local changes to GitHub, then pull on NAS and restart containers.
set -e

NAS_USER=xelllee
NAS_HOST=192.168.50.184
NAS_PASS="zell@521"
NAS_DIR=/volume1/docker/openclaw
DOCKER=/usr/local/bin/docker

# force password auth — prevents SSH from trying all keys and hitting MaxAuthTries
SSH_OPTS="-o StrictHostKeyChecking=no -o PreferredAuthentications=password -o IdentitiesOnly=yes"
nas() { sshpass -p "$NAS_PASS" ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "$@"; }

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
nas "cat > $NAS_DIR/.env" < .env \
  && ok ".env synced to $NAS_HOST:$NAS_DIR/.env" \
  || fail ".env sync failed"

# 3. Pull on NAS via git container
step 3 "git pull on NAS"
nas "echo '$NAS_PASS' | sudo -S $DOCKER run --rm \
    -v /var/services/homes/$NAS_USER/.ssh:/root/.ssh:ro \
    -v $NAS_DIR/repo:/repo \
    -w /repo \
    alpine/git -c safe.directory=/repo pull 2>&1" \
  && ok "repo updated on NAS" \
  || fail "git pull on NAS failed"

# copy docker-compose.yml from repo to deploy dir
nas "cp $NAS_DIR/repo/docker-compose.yml $NAS_DIR/docker-compose.yml" \
  && ok "docker-compose.yml updated from repo" \
  || fail "failed to copy docker-compose.yml"

# ensure required dirs exist on NAS
nas "mkdir -p $NAS_DIR/config $NAS_DIR/workspace" \
  && ok "config and workspace dirs ready" \
  || fail "failed to create dirs"

# 4. Restart openclaw-gateway
step 4 "restart openclaw-gateway"
nas "echo '$NAS_PASS' | sudo -S $DOCKER-compose -f $NAS_DIR/docker-compose.yml up -d --force-recreate openclaw-gateway 2>&1" \
  && ok "openclaw-gateway restarted" \
  || fail "docker-compose restart failed"

echo
log "deploy complete → http://$NAS_HOST:18789"
