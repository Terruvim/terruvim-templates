# Base stage
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache libc6-compat

# Dependencies stage
FROM base AS deps
COPY package*.json ./
RUN npm install --only=production

# Build stage
FROM base AS builder
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM base AS runner
ENV NODE_ENV=production
WORKDIR /app

# Copy necessary files
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs
USER nestjs

EXPOSE 8080

CMD ["node", "dist/main"]
