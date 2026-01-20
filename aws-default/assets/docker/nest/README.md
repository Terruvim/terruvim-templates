# Demo Backend - NestJS

NestJS backend API service for Project42.

## Description

This is the backend API service that handles business logic. It runs behind an ALB with Transform URL enabled, which strips the `/api` prefix before forwarding requests.

## Architecture

- **ALB Pattern**: `/api/*` (priority 100)
- **ALB Transform**: Strips `/api` prefix → forwards to container without prefix
- **Container Port**: 3000
- **Health Check**: `/health` (returns JSON status)

### Example Request Flow:
```
Client: https://api.dev.yourdns.com/api/health
   ↓
ALB: Strips /api → forwards /health
   ↓
Container: Receives /health on port 3000
   ↓
Response: {"status": "ok", "timestamp": "...", "service": "demo-be-nestjs"}
```

## Installation

```bash
$ npm install
```

## Running the app

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Test

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Docker Build

```bash
# Build image
docker build -t demo-be-nestjs .

# Run container
docker run -p 3000:3000 demo-be-nestjs
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `CORS_ORIGIN` - CORS origin (default: *)
- `DATABASE_URL` - PostgreSQL connection string
- `NODE_ENV` - Environment (development/production)

## Health Check

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:00:00.000Z",
  "service": "demo-be-nestjs",
  "version": "1.0.0"
}
```

## Notes

- The ALB Transform URL strips `/api` prefix, so the application receives requests without it
- Global prefix is set to empty string in `main.ts`
- Health endpoint is at `/health` (not `/api/health` because ALB strips the prefix)
- When deployed, access via: `https://api.dev.yourdns.com/api/health`
