# claw — OpenClaw NAS Deployment

Self-hosted [OpenClaw](https://openclaw.ai) gateway on Synology NAS — connects chat apps (Telegram, Discord, Slack, WhatsApp) to AI coding agents.

## Stack

- `ghcr.io/openclaw/openclaw:latest` — gateway + CLI
- LLM via [OpenRouter](https://openrouter.ai)

---

## Local Setup

```bash
# credentials (not committed to git — kept in .secret)
# .env is generated from .secret and auto-synced to NAS by deploy.sh
```

`.env` vars:

```env
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
OPENCLAW_GATEWAY_TOKEN=<long-random-token>
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_TZ=Asia/Shanghai
OPENROUTER_API_KEY=...
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
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
4. Restart the `openclaw-gateway` container

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

View gateway logs:

```bash
echo 'zell@521' | sudo -S /usr/local/bin/docker logs -f openclaw-gateway
```

Run CLI (onboarding, config):

```bash
echo 'zell@521' | sudo -S /usr/local/bin/docker-compose -f /volume1/docker/openclaw/docker-compose.yml run --rm openclaw-cli
```

---

## Access

```
http://192.168.50.184:18789
```

Health checks (no auth required):
- `http://192.168.50.184:18789/healthz`
- `http://192.168.50.184:18789/readyz`
