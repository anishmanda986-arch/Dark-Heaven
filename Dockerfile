# =============================================================================
# Dockerfile — Multi-Stage Production Build
# Stage 1: deps  — install production dependencies
# Stage 2: build — compile TypeScript
# Stage 3: prod  — minimal production image
# =============================================================================

# ─── Stage 1: Dependency Installation ────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Install build tools for native addons
RUN apk add --no-cache python3 make g++

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci --only=production && \
    npx prisma generate

# ─── Stage 2: TypeScript Build ────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
COPY tsconfig.json ./
COPY prisma ./prisma/

RUN npm ci

COPY src ./src

RUN npm run build && \
    npx prisma generate

# ─── Stage 3: Production Image ────────────────────────────────────────────────
FROM node:20-alpine AS production

# Security: run as non-root
RUN addgroup --system --gid 1001 botgroup && \
    adduser --system --uid 1001 botuser

WORKDIR /app

# Copy production node_modules from deps stage
COPY --from=deps --chown=botuser:botgroup /app/node_modules ./node_modules
COPY --from=deps --chown=botuser:botgroup /app/prisma ./prisma

# Copy compiled application
COPY --from=build --chown=botuser:botgroup /app/dist ./dist
COPY --from=build --chown=botuser:botgroup /app/package.json ./package.json

# Create logs directory
RUN mkdir -p logs && chown botuser:botgroup logs

USER botuser

# Health check via the API server
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

EXPOSE 3000

# Run database migrations then start the bot
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
