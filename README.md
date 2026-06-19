# 🚀 Discord OAuth2 Community Onboarding Bot

A production-grade Discord bot for managing community synchronization via OAuth2. Built with Discord.js v14, TypeScript, PostgreSQL, and Redis.

---

## ✨ Features

| Feature | Description |
|---|---|
| **OAuth2 Auth** | Full Discord OAuth2 with `identify`, `guilds.join` scopes |
| **Encrypted Storage** | AES-256-CBC token encryption at rest |
| **Queue-Based Joins** | Configurable delay, retries, and rate limit handling |
| **Live Dashboard** | Real-time progress embeds with progress bars |
| **Campaign Management** | Create, run, pause, and stop named campaigns |
| **Analytics** | Per-campaign and global join statistics |
| **Audit Logs** | Full audit trail of all bot actions |
| **Health Monitoring** | `/health` command + HTTP endpoint |
| **Docker Ready** | Multi-stage Dockerfile + docker-compose |

---

## 📋 Prerequisites

- Node.js ≥ 20.x
- PostgreSQL ≥ 14
- Redis ≥ 7
- A Discord Application with a Bot token
- Discord Application with OAuth2 configured

---

## ⚡ Quick Start

### 1. Clone & Install

```bash
git clone <repo-url>
cd discord-onboarding-bot
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values. The required fields are:

| Variable | Description |
|---|---|
| `DISCORD_TOKEN` | Bot token from Discord Developer Portal |
| `DISCORD_CLIENT_ID` | Application ID |
| `DISCORD_CLIENT_SECRET` | OAuth2 client secret |
| `DISCORD_REDIRECT_URI` | Must match your OAuth2 redirect in Dev Portal |
| `BOT_OWNER_ID` | Your Discord user ID (all admin commands are owner-only) |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `ENCRYPTION_KEY` | 64-char hex string (generate: `openssl rand -hex 32`) |

### 3. Set Up Database

```bash
# Run migrations
npm run db:migrate

# Generate Prisma client
npm run db:generate

# Optional: seed sample data
npm run db:seed
```

### 4. Deploy Discord Commands

```bash
# Deploy to a specific guild (instant, for development):
DEPLOY_GUILD_ID=your_guild_id npm run deploy:commands

# Deploy globally (1 hour propagation):
npm run deploy:commands
```

### 5. Start the Bot

```bash
# Development (hot reload)
npm run dev

# Production
npm run build
npm start
```

---

## 🐳 Docker Deployment

### Production

```bash
# Copy and fill environment file
cp .env.example .env

# Build and start all services
docker compose up -d

# Check logs
docker compose logs -f bot
```

### Development (with PgAdmin)

```bash
docker compose --profile dev up -d
# PgAdmin: http://localhost:5050 (admin@admin.com / admin)
```

---

## 🔐 OAuth2 Setup

### Discord Developer Portal

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Select your application → **OAuth2** → **General**
3. Add your redirect URI (e.g., `https://yourdomain.com/auth/callback`)
4. Copy the **Client ID** and **Client Secret**

### OAuth2 Flow

1. Direct users to: `https://yourdomain.com/auth/authorize`
2. Users authorize with Discord (grants `identify`, `guilds.join`)
3. Discord redirects to `/auth/callback` with an authorization code
4. Bot exchanges code for tokens, encrypts and stores them
5. Users are now authorized and will be included in future sync campaigns

### Required Bot Permissions

Your bot must be in the target server with these permissions:
- `CREATE_INSTANT_INVITE` or `MANAGE_GUILD`
- The bot must have a role **higher** than the default role to add members

---

## 🎮 Commands

All commands are **owner-only** (controlled by `BOT_OWNER_ID`).

### `/join`

Start a synchronization campaign immediately.

```
/join server_id:<target_server_id> [campaign_name:<name>] [delay_ms:<1500>]
```

- Shows a confirmation dialog before starting
- Displays a live dashboard embed with real-time progress
- Supports stopping mid-campaign with a button

### `/campaign`

Manage campaigns.

```
/campaign create name:<name> server_id:<id> [delay_ms:<ms>]
/campaign status campaign_id:<id>
/campaign stop campaign_id:<id>
/campaign list [page:<n>]
```

### `/users`

List all authorized users with token status.

```
/users [page:<n>]
```

### `/stats`

View global statistics (total users, campaigns, join success rate).

### `/health`

Check database, Redis, and Discord API health.

### `/settings`

Configure per-server settings.

```
/settings view
/settings set key:<setting> value:<value>
```

---

## 🏗️ Architecture

```
src/
├── api/              # Express OAuth2 callback server
├── commands/         # Slash command handlers
├── config/           # Zod-validated environment config
├── database/         # Prisma & Redis clients
├── embeds/           # Discord embed builders
├── middleware/        # Event handlers, guards
├── repositories/     # Data access layer (Repository Pattern)
├── services/         # Business logic (OAuth, Join)
├── types/            # TypeScript interfaces & enums
└── utils/            # Logger, encryption, UI helpers
```

### Data Flow: Join Campaign

```
/join command
  → Confirmation dialog
  → Campaign created (DB)
  → Users loaded (with valid OAuth tokens)
  → PQueue processes users:
      → Token validation/refresh
      → Discord API: PUT /guilds/{id}/members/{userId}
      → Success/failure logged (DB)
      → Progress updated (Redis)
      → Dashboard embed updated (Discord)
  → Campaign marked complete
  → Summary embed posted
```

### Security Model

- All tokens encrypted with AES-256-CBC before storage
- Unique IV per token — no two ciphertexts are the same
- Encryption key lives only in environment variables
- All admin commands require `BOT_OWNER_ID` match
- Express API protected with Helmet + rate limiting
- Database uses parameterized queries (Prisma prevents SQL injection)

---

## 📊 Database Schema

```
users
  ├── oauth_tokens (encrypted access/refresh tokens)
  └── join_logs
      └── campaigns
          ├── campaign_users
          └── campaign_stats

audit_logs
global_stats
guild_settings
```

---

## 🔧 Configuration Reference

| Variable | Default | Description |
|---|---|---|
| `GUILD_JOIN_DELAY_MS` | `1500` | Milliseconds between join operations |
| `MAX_RETRIES` | `3` | Maximum retry attempts per user |
| `MAX_CONCURRENT_JOINS` | `1` | Concurrent join operations (keep at 1 for safety) |
| `RATE_LIMIT_REQUESTS` | `50` | API rate limit requests per window |
| `RATE_LIMIT_WINDOW_MS` | `1000` | Rate limit window in milliseconds |
| `LOG_LEVEL` | `info` | Winston log level |

---

## 🚀 Production Checklist

- [ ] `ENCRYPTION_KEY` is a cryptographically random 32-byte hex value
- [ ] `NODE_ENV=production` is set
- [ ] Database is backed up regularly
- [ ] Redis has AOF persistence enabled
- [ ] Bot has correct permissions in target guilds
- [ ] OAuth2 redirect URI matches exactly (including protocol)
- [ ] API server is behind a reverse proxy (nginx/Caddy) with TLS
- [ ] Docker compose uses named volumes for data persistence
- [ ] Log rotation configured (handled by winston-daily-rotate-file)

---

## 📄 License

MIT
