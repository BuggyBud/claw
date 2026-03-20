#!/bin/bash
# Deploy: push local changes to GitHub, then pull on NAS and restart containers.
set -e

NAS_USER=xelllee
NAS_HOST=192.168.50.184
NAS_PASS="zell@521"
NAS_DIR=/volume1/docker/openclaw
DOCKER=/usr/local/bin/docker

# 1. Push to GitHub
echo "[1/4] pushing to GitHub..."
git push origin main

# 2. Sync .env to NAS
echo "[2/4] syncing .env to NAS..."
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "cat > $NAS_DIR/.env" < .env

# 3. Pull on NAS via git container
echo "[3/4] pulling on NAS..."
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "echo '$NAS_PASS' | sudo -S $DOCKER run --rm \
    -v /var/services/homes/$NAS_USER/.ssh:/root/.ssh:ro \
    -v $NAS_DIR/repo:/repo \
    -w /repo \
    alpine/git pull 2>&1"

# 4. Restart openclaw container
echo "[4/4] restarting openclaw on NAS..."
sshpass -p "$NAS_PASS" ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_HOST" \
  "echo '$NAS_PASS' | sudo -S $DOCKER-compose -f $NAS_DIR/docker-compose.yml up -d --force-recreate openclaw 2>&1"

echo "done. openclaw is live at http://$NAS_HOST:3000"
