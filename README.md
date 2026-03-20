# claw — OpenClaw NAS Deployment

OpenClaw agent running on Synology NAS with Postgres + Redis.

## Stack

- `openclawai/openclaw:latest` — agent core
- `postgres:15` — state/tasks
- `redis:7` — memory/cache
- LLM via [OpenRouter](https://openrouter.ai)

---

## Local Setup

```bash
# credentials (not committed to git)
cp .secret .env   # or generate manually — see .env format below
```

`.env` format:

```env
OPENROUTER_API_KEY=...
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
NODE_ENV=production
PORT=3000
POSTGRES_USER=openclaw
POSTGRES_PASSWORD=...
POSTGRES_DB=openclaw
REDIS_URL=redis://redis:6379
TWITTER_API_KEY=...
TWITTER_API_SECRET=...
TWITTER_ACCESS_TOKEN=...
TWITTER_ACCESS_SECRET=...
```

---

## Workflow

```
edit locally → commit → ./deploy.sh
```

### 1. Commit changes

```bash
git add .
git commit -m "your message"
```

### 2. Deploy to NAS

```bash
./deploy.sh
```

This will:
1. `git push origin main`
2. Sync `.env` to NAS (never committed to git)
3. Pull latest on NAS (`192.168.50.184`) via git container
4. Restart the `openclaw` container

---

## NAS — Manual Commands

SSH into NAS:

```bash
ssh xelllee@192.168.50.184
```

Start all services:

```bash
echo 'zell@521' | sudo -S /usr/local/bin/docker-compose -f /volume1/docker/openclaw/docker-compose.yml up -d
```

Stop all services:

```bash
echo 'zell@521' | sudo -S /usr/local/bin/docker-compose -f /volume1/docker/openclaw/docker-compose.yml down
```

View openclaw logs:

```bash
echo 'zell@521' | sudo -S /usr/local/bin/docker logs -f openclaw
```

Pull latest and restart (manual deploy):

```bash
echo 'zell@521' | sudo -S /volume1/docker/openclaw/deploy.sh
```

---

## Access

```
http://192.168.50.184:3000
```
